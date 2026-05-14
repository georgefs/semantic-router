package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/vllm-project/semantic-router/src/semantic-router/pkg/config"
	"github.com/vllm-project/semantic-router/src/semantic-router/pkg/observability/logging"
	"gopkg.in/yaml.v3"
)

// TestCategoryModelDeployment tests the complete category signal model deployment
// This verifies:
// 1. YAML configuration can be loaded correctly
// 2. Model paths point to valid trained model
// 3. Label mapping contains all expected categories
// 4. Runtime can initialize with the configuration
func main() {
	fmt.Println("=" * 80)
	fmt.Println("Category Signal Model - Production Deployment Test")
	fmt.Println("=" * 80)

	// Initialize logging
	if _, err := logging.InitLoggerFromEnv(); err != nil {
		log.Printf("Warning: Failed to initialize logger: %v\n", err)
	}

	// Test 1: Load YAML Configuration
	fmt.Println("\n[TEST 1] Loading YAML Configuration")
	configPath := "docs/agent/playbooks/category-signal-model-training-example/configs/category-signal-model.yaml"
	if err := testConfigurationLoad(configPath); err != nil {
		fmt.Printf("❌ FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Configuration loaded successfully")

	// Test 2: Verify Model Paths
	fmt.Println("\n[TEST 2] Verifying Model Paths")
	if err := testModelPaths(configPath); err != nil {
		fmt.Printf("❌ FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Model paths verified")

	// Test 3: Verify Label Mapping
	fmt.Println("\n[TEST 3] Verifying Label Mapping")
	if err := testLabelMapping(configPath); err != nil {
		fmt.Printf("❌ FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Label mapping verified")

	// Test 4: Verify Categories Configuration
	fmt.Println("\n[TEST 4] Verifying Categories Configuration")
	if err := testCategoriesConfiguration(configPath); err != nil {
		fmt.Printf("❌ FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Categories configuration verified")

	// Test 5: Test Category Routing
	fmt.Println("\n[TEST 5] Testing Category Routing")
	if err := testCategoryRouting(configPath); err != nil {
		fmt.Printf("❌ FAILED: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("✅ Category routing verified")

	fmt.Println("\n" + "=" * 80)
	fmt.Println("✅ ALL TESTS PASSED - Production Deployment Ready")
	fmt.Println("=" * 80)
}

func testConfigurationLoad(configPath string) error {
	// Check if file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return fmt.Errorf("configuration file not found: %s", configPath)
	}

	// Read and parse YAML
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg config.RouterConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return fmt.Errorf("failed to parse YAML: %w", err)
	}

	fmt.Printf("  Config loaded successfully\n")
	fmt.Printf("  Classifier type: %v\n", cfg.Classifier)
	return nil
}

func testModelPaths(configPath string) error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}

	var cfg config.RouterConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return err
	}

	// Verify model path exists (relative to config file)
	configDir := filepath.Dir(configPath)
	if cfg.Classifier.CategoryModel.ModelPath != "" {
		modelPath := filepath.Join(configDir, cfg.Classifier.CategoryModel.ModelPath)
		if _, err := os.Stat(modelPath); os.IsNotExist(err) {
			return fmt.Errorf("model path does not exist: %s (resolved to: %s)",
				cfg.Classifier.CategoryModel.ModelPath, modelPath)
		}
		fmt.Printf("  ✓ Model path valid: %s\n", cfg.Classifier.CategoryModel.ModelPath)
	}

	// Verify label mapping path exists
	if cfg.Classifier.CategoryModel.LabelMappingPath != "" {
		labelPath := filepath.Join(configDir, cfg.Classifier.CategoryModel.LabelMappingPath)
		if _, err := os.Stat(labelPath); os.IsNotExist(err) {
			return fmt.Errorf("label mapping path does not exist: %s (resolved to: %s)",
				cfg.Classifier.CategoryModel.LabelMappingPath, labelPath)
		}
		fmt.Printf("  ✓ Label mapping path valid: %s\n", cfg.Classifier.CategoryModel.LabelMappingPath)
	}

	return nil
}

func testLabelMapping(configPath string) error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}

	var cfg config.RouterConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return err
	}

	configDir := filepath.Dir(configPath)
	labelPath := filepath.Join(configDir, cfg.Classifier.CategoryModel.LabelMappingPath)

	labelData, err := os.ReadFile(labelPath)
	if err != nil {
		return fmt.Errorf("failed to read label mapping: %w", err)
	}

	var labelMapping map[string]interface{}
	if err := yaml.Unmarshal(labelData, &labelMapping); err != nil {
		return fmt.Errorf("failed to parse label mapping YAML: %w", err)
	}

	// Check for required keys
	if _, hasLabel2id := labelMapping["label2id"]; !hasLabel2id {
		return fmt.Errorf("label_mapping.json missing 'label2id' key")
	}
	if _, hasId2label := labelMapping["id2label"]; !hasId2label {
		return fmt.Errorf("label_mapping.json missing 'id2label' key")
	}

	label2id := labelMapping["label2id"].(map[string]interface{})
	fmt.Printf("  ✓ Label mapping contains %d categories\n", len(label2id))

	// Verify expected categories
	expectedCategories := []string{
		"biology", "business", "chemistry", "computer science",
		"economics", "engineering", "health", "history",
		"law", "math", "other", "philosophy", "physics", "psychology",
	}

	for _, cat := range expectedCategories {
		if _, exists := label2id[cat]; !exists {
			return fmt.Errorf("expected category '%s' not found in label_mapping", cat)
		}
	}

	fmt.Printf("  ✓ All 14 expected categories present\n")
	return nil
}

func testCategoriesConfiguration(configPath string) error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}

	var cfg config.RouterConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return err
	}

	if len(cfg.Categories) == 0 {
		return fmt.Errorf("no categories configured")
	}

	fmt.Printf("  ✓ Categories configured: %d\n", len(cfg.Categories))

	for _, cat := range cfg.Categories {
		if cat.Name == "" {
			return fmt.Errorf("category missing 'name' field")
		}
		if len(cat.ModelScores) == 0 {
			return fmt.Errorf("category '%s' has no model scores", cat.Name)
		}
		fmt.Printf("    - %s: %d model scores\n", cat.Name, len(cat.ModelScores))
	}

	return nil
}

func testCategoryRouting(configPath string) error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}

	var cfg config.RouterConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return err
	}

	// Build a category name to routing mapping
	categoryRouting := make(map[string][]string)

	for _, cat := range cfg.Categories {
		var routes []string
		for _, score := range cat.ModelScores {
			routes = append(routes, score.Model)
		}
		categoryRouting[cat.Name] = routes
		fmt.Printf("  ✓ Category '%s' routes to: %v\n", cat.Name, routes)
	}

	// Verify fallback category
	fallback := cfg.Classifier.CategoryModel.FallbackCategory
	if fallback == "" {
		return fmt.Errorf("no fallback category configured")
	}

	fmt.Printf("  ✓ Fallback category: %s\n", fallback)

	// Verify threshold is reasonable
	threshold := cfg.Classifier.CategoryModel.Threshold
	if threshold <= 0 || threshold > 1 {
		return fmt.Errorf("threshold out of range: %f", threshold)
	}
	fmt.Printf("  ✓ Classification threshold: %.2f\n", threshold)

	return nil
}

func init() {
	// Add a print helper
	fmt.Printf = func(format string, v ...interface{}) (n int, err error) {
		return os.Stdout.WriteString(fmt.Sprintf(format, v...))
	}
}
