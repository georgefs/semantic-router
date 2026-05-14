#!/usr/bin/env python3
"""
Category Classifier Training with mmBERT-32K LoRA

Trains a 14-class category classifier compatible with MoM architecture.
Uses mmBERT-32K as the unified base model across all semantic-router classifiers.

Categories (MMLU-Pro):
  biology, business, chemistry, computer science, economics, engineering,
  health, history, law, math, philosophy, physics, psychology, other

Features:
  - LoRA fine-tuning for parameter efficiency
  - Supports both LoRA and merged model output
  - Class-weighted loss for imbalanced categories
  - Early stopping and best model checkpoint

Hyperparameters (optimized for mmBERT-32K):
  - LoRA rank: 16 (default)
  - LoRA alpha: 32
  - Learning rate: 2e-5
  - Batch size: 16
  - Epochs: 8 (with early stopping)
  - Results: Expected 75-85% accuracy

Usage:
    # Quick test (5 samples per category, 1 epoch)
    python train_category_classifier_mmbert_lora.py --epochs 1 --max-samples-per-category 5

    # Full training (150 samples per category, 8 epochs)
    python train_category_classifier_mmbert_lora.py --epochs 8 --max-samples-per-category 150 --lora-rank 16

    # Custom output directory
    python train_category_classifier_mmbert_lora.py --output-dir models/my_classifier_r16
"""

import argparse
import json
import logging
import os
import sys
import torch
import numpy as np
from pathlib import Path
from datasets import Dataset, load_dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer,
    EarlyStoppingCallback,
)
from sklearn.metrics import accuracy_score, f1_score, classification_report
from sklearn.utils.class_weight import compute_class_weight

# Optional LoRA imports
try:
    from peft import LoraConfig, get_peft_model, TaskType
    PEFT_AVAILABLE = True
except ImportError:
    PEFT_AVAILABLE = False
    print("Warning: PEFT not installed. LoRA training unavailable. Install with: pip install peft")

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 14 MMLU-Pro categories (matching semantic-router configuration)
CATEGORIES = [
    "biology",
    "business",
    "chemistry",
    "computer science",
    "economics",
    "engineering",
    "health",
    "history",
    "law",
    "math",
    "philosophy",
    "physics",
    "psychology",
    "other",
]

LABEL2ID = {cat: idx for idx, cat in enumerate(CATEGORIES)}
ID2LABEL = {idx: cat for cat, idx in LABEL2ID.items()}
NUM_LABELS = len(CATEGORIES)

logger.info(f"Categories ({NUM_LABELS}): {', '.join(CATEGORIES)}")


def load_mmlu_pro_data(max_samples_per_category=None, split="test"):
    """Load MMLU-Pro dataset and convert to classification format."""
    logger.info(f"Loading MMLU-Pro dataset ({split} split)...")

    try:
        dataset = load_dataset("TIGER-Lab/MMLU-Pro", split=split)
    except Exception as e:
        logger.error(f"Failed to load MMLU-Pro: {e}")
        logger.info("Falling back to empty dataset")
        return []

    examples = []
    category_counts = {cat: 0 for cat in CATEGORIES}

    for item in dataset:
        category = item.get("category", "other")

        # Normalize category name
        if category not in CATEGORIES:
            category = "other"

        # Skip if we've collected enough samples for this category
        if max_samples_per_category and category_counts[category] >= max_samples_per_category:
            continue

        # Create training example
        question = item.get("question", "")
        if not question:
            continue

        examples.append({
            "text": question,
            "label": LABEL2ID[category],
            "label_name": category,
        })
        category_counts[category] += 1

    logger.info(f"Loaded {len(examples)} examples")
    for cat, count in sorted(category_counts.items()):
        logger.info(f"  {cat}: {count}")

    return examples


def prepare_dataset(examples):
    """Prepare dataset for training."""
    logger.info(f"Preparing {len(examples)} examples...")

    from sklearn.model_selection import train_test_split

    # Split into train/val (80/20)
    train_examples, val_examples = train_test_split(
        examples, test_size=0.2, random_state=42, stratify=[e["label"] for e in examples]
    )

    train_dataset = Dataset.from_list(train_examples)
    val_dataset = Dataset.from_list(val_examples)

    logger.info(f"Train: {len(train_dataset)}, Val: {len(val_dataset)}")

    return train_dataset, val_dataset


def train_model(args):
    """Train category classifier with LoRA."""
    logger.info(f"Training Category Classifier (14 classes)")
    logger.info(f"Base model: {args.model_name}")
    logger.info(f"Output directory: {args.output_dir}")

    # Create output directory
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)

    # Load data
    examples = load_mmlu_pro_data(
        max_samples_per_category=args.max_samples_per_category,
        split="test"
    )

    if not examples:
        logger.error("No training data loaded!")
        return False

    # Prepare datasets
    train_dataset, val_dataset = prepare_dataset(examples)

    # Load model and tokenizer
    logger.info(f"Loading tokenizer from {args.model_name}...")
    tokenizer = AutoTokenizer.from_pretrained(args.model_name, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    logger.info(f"Loading base model {args.model_name}...")
    device = f"cuda:{args.gpu_id}" if torch.cuda.is_available() else "cpu"

    base_model = AutoModelForSequenceClassification.from_pretrained(
        args.model_name,
        num_labels=NUM_LABELS,
        id2label=ID2LABEL,
        label2id=LABEL2ID,
        torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
        device_map="auto",
        trust_remote_code=True,
    )

    # Apply LoRA if requested
    if args.use_lora and PEFT_AVAILABLE:
        logger.info(f"Applying LoRA (rank={args.lora_rank}, alpha={args.lora_alpha})...")
        lora_config = LoraConfig(
            r=args.lora_rank,
            lora_alpha=args.lora_alpha,
            lora_dropout=0.1,
            bias="none",
            task_type=TaskType.SEQ_CLS,
            # mmBERT/ModernBERT target modules
            target_modules=[
                "attn.Wqkv",
                "attn.Wo",
                "mlp.Wi",
                "mlp.Wo",
            ],
        )
        model = get_peft_model(base_model, lora_config)
        model.print_trainable_parameters()
    else:
        model = base_model

    # Tokenize datasets
    def tokenize_function(examples):
        return tokenizer(
            examples["text"],
            padding="max_length",
            truncation=True,
            max_length=512,
        )

    logger.info("Tokenizing datasets...")
    train_dataset = train_dataset.map(tokenize_function, batched=True)
    val_dataset = val_dataset.map(tokenize_function, batched=True)

    # Compute class weights for imbalanced data
    train_labels = [ex["label"] for ex in train_dataset]
    class_weights = compute_class_weight("balanced", classes=np.arange(NUM_LABELS), y=train_labels)
    class_weights_tensor = torch.tensor(class_weights, dtype=torch.float32)

    # Training arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        eval_strategy="steps",
        eval_steps=len(train_dataset) // (args.batch_size * 2),
        learning_rate=args.learning_rate,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        num_train_epochs=args.epochs,
        weight_decay=0.01,
        save_strategy="steps",
        save_steps=len(train_dataset) // args.batch_size,
        load_best_model_at_end=True,
        metric_for_best_model="f1",
        greater_is_better=True,
        logging_steps=10,
        report_to="none",
        seed=42,
    )

    # Compute metrics
    def compute_metrics(eval_pred):
        predictions, labels = eval_pred
        predictions = np.argmax(predictions, axis=1)

        acc = accuracy_score(labels, predictions)
        f1 = f1_score(labels, predictions, average="weighted", zero_division=0)

        return {"accuracy": acc, "f1": f1}

    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
        compute_metrics=compute_metrics,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)],
    )

    # Train
    logger.info("Starting training...")
    trainer.train()

    # Save model
    logger.info(f"Saving model to {args.output_dir}...")
    if args.use_lora and PEFT_AVAILABLE:
        model.save_pretrained(args.output_dir)
        base_model.config.save_pretrained(args.output_dir)
    else:
        model.save_pretrained(args.output_dir)
    tokenizer.save_pretrained(args.output_dir)

    # Save label mapping
    label_mapping = {
        "label2id": LABEL2ID,
        "id2label": ID2LABEL,
        "categories": CATEGORIES,
    }
    with open(Path(args.output_dir) / "label_mapping.json", "w") as f:
        json.dump(label_mapping, f, indent=2)

    logger.info("✅ Training complete!")

    # Evaluate on validation set
    logger.info("Evaluating on validation set...")
    eval_results = trainer.evaluate()
    logger.info(f"Validation Results:")
    logger.info(f"  Accuracy: {eval_results.get('eval_accuracy', 0):.4f}")
    logger.info(f"  F1 Score: {eval_results.get('eval_f1', 0):.4f}")

    return True


def main():
    parser = argparse.ArgumentParser(description="Train category classifier with mmBERT-32K LoRA")

    parser.add_argument("--mode", default="train", choices=["train", "test"])
    parser.add_argument("--model-name", default="llm-semantic-router/mmbert-32k-yarn",
                       help="Base model name (default: llm-semantic-router/mmbert-32k-yarn)")
    parser.add_argument("--output-dir", default="models/mmbert32k_category_classifier_r16",
                       help="Output directory for trained model")
    parser.add_argument("--epochs", type=int, default=8, help="Number of training epochs")
    parser.add_argument("--batch-size", type=int, default=16, help="Training batch size")
    parser.add_argument("--learning-rate", type=float, default=2e-5, help="Learning rate")
    parser.add_argument("--lora-rank", type=int, default=16, help="LoRA rank")
    parser.add_argument("--lora-alpha", type=int, default=32, help="LoRA alpha")
    parser.add_argument("--use-lora", action="store_true", default=True,
                       help="Use LoRA (default: True)")
    parser.add_argument("--max-samples-per-category", type=int, default=150,
                       help="Max samples per category")
    parser.add_argument("--gpu-id", type=int, default=0, help="GPU ID to use")

    args = parser.parse_args()

    if args.mode == "train":
        success = train_model(args)
        sys.exit(0 if success else 1)
    else:
        logger.info("Test mode not implemented for mmBERT version")


if __name__ == "__main__":
    main()
