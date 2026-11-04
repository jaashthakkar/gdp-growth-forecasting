# ==========================================================
# Comparative Analysis of GDP Growth:
# Linear Regression vs. Decision Tree Regression
# Jaash Thakkar · DATA 508 · Purdue University
# ==========================================================

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(rpart)

dir.create("images", showWarnings = FALSE)

# ---------------------------------------------------------
# 1. Load World Bank GDP growth data (annual %, NY.GDP.MKTP.KD.ZG)
#    Download the CSV from https://data.worldbank.org/indicator/NY.GDP.MKTP.KD.ZG
#    and save it in this folder as gdp_growth.csv
# ---------------------------------------------------------
gdp <- read_csv("gdp_growth.csv", skip = 4)

gdp_long <- gdp %>%
  pivot_longer(cols = `1960`:`2023`, names_to = "Year", values_to = "GDP_growth") %>%
  mutate(Year = as.numeric(Year)) %>%
  drop_na(GDP_growth)

# ---------------------------------------------------------
# 2. GDP growth over time: United States, China, India
# ---------------------------------------------------------
gdp_subset <- gdp_long %>%
  filter(`Country Name` %in% c("United States", "China", "India"))

plot1 <- ggplot(gdp_subset, aes(x = Year, y = GDP_growth, color = `Country Name`)) +
  geom_line(linewidth = 1) +
  labs(title = "GDP Growth Over Time", x = "Year", y = "GDP Growth (%)") +
  theme_minimal()
print(plot1)
ggsave("images/gdp_growth_over_time.png", plot = plot1, width = 8, height = 5)

# ---------------------------------------------------------
# 3. Feature engineering: previous year's GDP growth (lag)
# ---------------------------------------------------------
gdp_model <- gdp_long %>%
  group_by(`Country Name`) %>%
  arrange(Year) %>%
  mutate(GDP_lag = lag(GDP_growth)) %>%
  ungroup() %>%
  drop_na(GDP_lag)

# ---------------------------------------------------------
# 4. Linear regression
# ---------------------------------------------------------
lm_model <- lm(GDP_growth ~ GDP_lag, data = gdp_model)
summary(lm_model)
gdp_model$lm_pred <- predict(lm_model)

plot2 <- ggplot(gdp_model, aes(x = GDP_growth, y = lm_pred)) +
  geom_point(alpha = 0.4) +
  geom_abline(slope = 1, intercept = 0) +
  labs(title = "Actual vs Predicted GDP Growth: Linear Regression",
       x = "Actual GDP Growth", y = "Predicted GDP Growth") +
  theme_minimal()
print(plot2)
ggsave("images/linear_regression_actual_vs_predicted.png", plot = plot2, width = 8, height = 5)

# ---------------------------------------------------------
# 5. Decision tree regression
# ---------------------------------------------------------
tree_model <- rpart(GDP_growth ~ GDP_lag, data = gdp_model)
gdp_model$tree_pred <- predict(tree_model)

plot3 <- ggplot(gdp_model, aes(x = GDP_growth, y = tree_pred)) +
  geom_point(alpha = 0.4) +
  geom_abline(slope = 1, intercept = 0) +
  labs(title = "Actual vs Predicted GDP Growth: Decision Tree",
       x = "Actual GDP Growth", y = "Predicted GDP Growth") +
  theme_minimal()
print(plot3)
ggsave("images/decision_tree_actual_vs_predicted.png", plot = plot3, width = 8, height = 5)

# ---------------------------------------------------------
# 6. Model comparison: R-squared and RMSE
# ---------------------------------------------------------
metrics <- function(actual, pred) {
  c(R2 = 1 - sum((actual - pred)^2) / sum((actual - mean(actual))^2),
    RMSE = sqrt(mean((actual - pred)^2)))
}
results <- rbind(
  `Linear Regression` = metrics(gdp_model$GDP_growth, gdp_model$lm_pred),
  `Decision Tree`     = metrics(gdp_model$GDP_growth, gdp_model$tree_pred)
)
cat("\nObservations:", nrow(gdp_model), " Countries/regions:", n_distinct(gdp_model$`Country Name`), "\n\n")
print(round(results, 3))
