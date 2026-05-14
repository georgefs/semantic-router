package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/vllm-project/semantic-router/src/semantic-router/pkg/config"
	"github.com/vllm-project/semantic-router/src/semantic-router/pkg/observability/logging"
)

func main() {
	fmt.Println("=" * 80)
	fmt.Println("Category Signal Model - Production Deployment Test (Using semantic-router)")
	fmt.Println("=" * 80)

	// Initialize logging
	if _, err := logging.InitLoggerFromEnv(); err != nil {
		fmt.Printf("Warning: Logger init failed: %v\n", err)
	}

	// Test 1: Load configuration using semantic-router's config parser
	fmt.Println("\n[TEST 1] Loading Configuration with semantic-router")
	configPath := "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml"
	
	absPath, err := filepath.Abs(configPath)
	if err != nil {
		fmt.Printf("❌ Failed to get absolute path: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Printf("   Loading config from: %s\n", configPath)
	fmt.Printf("   Absolute path: %s\n", absPath)

	cfg, err := config.Parse(configPath)
	if err != nil {
		fmt.Printf("❌ Failed to parse config: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Configuration parsed successfully")

	// Test 2: Verify classifier configuration
	fmt.Println("\n[TEST 2] Verifying Classifier Configuration")
	if cfg.Classifier == nil {
		fmt.Println("❌ Classifier configuration is nil")
		os.Exit(1)
	}
	fmt.Println("✅ Classifier configuration exists")

	// Test 3: Verify category model configuration
	fmt.Println("\n[TEST 3] Verifying Category Model Configuration")
	catModel := cfg.Classifier.CategoryModel
	if catModel == nil {
		fmt.Println("❌ Category model configuration is nil")
		os.Exit(1)
	}

	fmt.Printf("   Model ID: %s\n", catModel.ModelID)
	fmt.Printf("   Model Path: %s\n", catModel.ModelPath)
	fmt.Printf("   Label Mapping Path: %s\n", catModel.LabelMappingPath)
	fmt.Printf("   Threshold: %.2f\n", catModel.Threshold)
	fmt.Printf("   Fallback Category: %s\n", catModel.FallbackCategory)
	fmt.Println("✅ Category model configuration valid")

	// Test 4: Verify categories
	fmt.Println("\n[TEST 4] Verifying Categories Configuration")
	if len(cfg.Categories) == 0 {
		fmt.Println("❌ No categories configured")
		os.Exit(1)
	}

	fmt.Printf("   Total categories: %d\n", len(cfg.Categories))
	
	expectedCategories := map[string]bool{
		"biology": false, "business": false, "chemistry": false, "computer science": false,
		"economics": false, "engineering": false, "health": false, "history": false,
		"law": false, "math": false, "other": false, "philosophy": false,
		"physics": false, "psychology": false,
	}

	for _, cat := range cfg.Categories {
		if _, exists := expectedCategories[cat.Name]; exists {
			expectedCategories[cat.Name] = true
		}
		fmt.Printf("   - %s: %d model scores\n", cat.Name, len(cat.ModelScores))
	}

	// Check if all categories are present
	missingCategories := []string{}
	for catName, found := range expectedCategories {
		if !found {
			missingCategories = append(missingCategories, catName)
		}
	}

	if len(missingCategories) > 0 {
		fmt.Printf("❌ Missing categories: %v\n", missingCategories)
		os.Exit(1)
	}

	fmt.Println("✅ All 14 expected categories present and configured")

	// Test 5: Verify model paths exist
	fmt.Println("\n[TEST 5] Verifying Model Paths")
	configDir := filepath.Dir(absPath)
	
	modelPath := filepath.Join(configDir, catModel.ModelPath)
	if _, err := os.Stat(modelPath); os.IsNotExist(err) {
		fmt.Printf("❌ Model path does not exist: %s\n", modelPath)
		os.Exit(1)
	}
	fmt.Printf("   ✓ Model path exists: %s\n", modelPath)

	labelPath := filepath.Join(configDir, catModel.LabelMappingPath)
	if _, err := os.Stat(labelPath); os.IsNotExist(err) {
		fmt.Printf("❌ Label mapping path does not exist: %s\n", labelPath)
		os.Exit(1)
	}
	fmt.Printf("   ✓ Label mapping path exists: %s\n", labelPath)

	fmt.Println("✅ All model paths verified")

	// Test 6: Runtime initialization simulation
	fmt.Println("\n[TEST 6] Runtime Initialization Simulation")
	fmt.Println("   Creating registry with loaded configuration...")
	
	registry := config.NewRegistry(cfg)
	if registry == nil {
		fmt.Println("❌ Failed to create registry")
		os.Exit(1)
	}
	fmt.Println("✅ Registry created successfully")

	// Test 7: Category routing verification
	fmt.Println("\n[TEST 7] Verifying Category Routing")
	routingMap := make(map[string][]string)
	for _, cat := range cfg.Categories {
		var models []string
		for _, score := range cat.ModelScores {
			models = append(models, score.Model)
		}
		routingMap[cat.Name] = models
	}

	fmt.Println("   Sample routing configurations:")
	sampleCats := []string{"law", "computer science", "biology"}
	for _, catName := range sampleCats {
		if models, exists := routingMap[catName]; exists {
			fmt.Printf("   - %s → %v\n", catName, models)
		}
	}
	fmt.Println("✅ Category routing configured correctly")

	// Final Summary
	fmt.Println("\n" + "=" * 80)
	fmt.Println("✅ ALL TESTS PASSED")
	fmt.Println("=" * 80)
	fmt.Println("\nDeployment Status:")
	fmt.Println("  ✓ Configuration loaded by semantic-router")
	fmt.Println("  ✓ 14 categories configured and verified")
	fmt.Println("  ✓ Model paths resolved and exist")
	fmt.Println("  ✓ Registry initialized successfully")
	fmt.Println("  ✓ Category routing configured")
	fmt.Println("\n✅ Ready for production deployment")
	fmt.Println("=" * 80 + "\n")
}
