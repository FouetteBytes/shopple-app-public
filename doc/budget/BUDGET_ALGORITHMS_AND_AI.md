# Budget & AI Analysis Algorithms

This document provides a comprehensive technical breakdown of the algorithms driving the "Smart Analysis" and "Budget Prediction" features in Shopple. These systems are engineered to provide deterministic, mathematically verifiable financial insights while maintaining 100% offline privacy.

---

## 1. Budget Analysis (Statistical AI)

The "AI Analysis" feature is powered by a **Statistical Anomaly Detection Engine**. Unlike Generative AI (LLMs) which can "hallucinate" or provide inconsistent answers, this system uses Statistical Process Control (SPC) methods — similar to those used in industrial quality assurance and algorithmic trading — to identify spending outliers with mathematical precision.

### A. Daily Spending Spikes (Z-Score Analysis)

The system constantly calculates a "Normal Baseline" for your spending and flags deviations.

**The Concept:**
We calculate a **Z-Score** for today's spending. A Z-Score tells us how many "Standard Deviations" ($\sigma$) away from the mean ($\mu$) a data point is. In a normal distribution, 95% of data points fall within 2 standard deviations. Anything beyond that is statistically significant (an anomaly).

**The Code Implementation:**
Found in `SpendingInsightsService._detectAnomalies`.

```dart
// 1. Check if we have enough history to establish a baseline
if (historical.avgDailySpend > 0 && historical.stdDeviation > 0) {
  
  // 2. Calculate Z-Score: (Value - Mean) / StandardDeviation
  final zScore = (current.todaySpent - historical.avgDailySpend) / historical.stdDeviation;

  // 3. Threshold Check: If Z-Score > 2.0, it is an anomaly (Top 5% outlier)
  if (zScore > 2.0) {
    anomalies.add(SpendingAnomaly(
      type: AnomalyType.unusuallyHighSpending,
      // If Z > 3.0 (Top 0.3% outlier), mark as High Severity
      severity: zScore > 3.0 ? AnomalySeverity.high : AnomalySeverity.medium, 
      message: 'Today\'s spending is ${zScore.toStringAsFixed(1)}x higher than usual',
      // ...
    ));
  }
}
```

**Real-World Example:**
Let's consider a scenario where you are on vacation.

1.  **Baseline Statistics (Your user profile):**
    *   **Average Daily Spend ($\mu$):** Rs 1,000
    *   **Standard Deviation ($\sigma$):** Rs 200 (This means usually, your spending fluctuates between Rs 800 and Rs 1,200).

2.  **Scenario A: A slightly expensive lunch (Rs 1,300)**
    *   **Calculation:** $(1300 - 1000) / 200 = 1.5$
    *   **Analysis:** The Z-Score is **1.5**. This is within the "Normal" range ($< 2.0$).
    *   **Result:** No Alert. The AI sees this as normal variation.

3.  **Scenario B: A shopping spree (Rs 1,700)**
    *   **Calculation:** $(1700 - 1000) / 200 = 3.5$
    *   **Analysis:** The Z-Score is **3.5**. This is exceptionally high ($> 3.0$).
    *   **Result:** **Red Alert**. The AI will display: "Critical Spending Alert: Today's spending is 3.5x higher than usual."

**Why Standard Deviation Matters:**
If you were a naturally erratic spender (e.g., spending Rs 500 one day, Rs 2000 the next), your Standard Deviation ($\sigma$) would be much higher (e.g., Rs 800).
*   In that case, a Rs 1,700 day would yield a Z-Score of $(1700 - 1000) / 800 = 0.875$.
*   The AI would **NOT** flag it, because for *you*, that volatility is normal. This makes the AI personalized to *your* habits, not a generic rule.

---

### B. Category Spikes (Relative Deviation)

For specific categories (e.g., "Groceries"), we use a simpler "Relative Deviation" model because category spending is often more sporadic than total daily spending.

**The Code Implementation:**
```dart
// 1. Calculate historical average for this specific category
final categoryAvg = categoryHistory.average();

// 2. Calculate Percentage Deviation
final deviation = (currentAmount - categoryAvg) / categoryAvg;

// 3. Threshold: > 50% deviation triggers an alert
if (deviation > 0.5) {
  anomalies.add(SpendingAnomaly(
    type: AnomalyType.categorySpike,
    message: '${category} spending is ${(deviation * 100)}% higher than average',
    // ...
  ));
}
```

---

### C. Budget Depletion Velocity

This algorithm prevents you from running out of money before the month ends by comparing "Time Elapsed" vs "Budget Consumed".

**The Concept:**
If you are 30% through the month, you should ideally have used ~30% of your budget. If you have used 60%, you are "burning" cash too fast.

**The Code Implementation:**
```dart
// 1. Calculate expected utilization based on date
final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
final expectedUtilization = now.day / daysInMonth; // e.g., 10th day of 30 = 0.33 (33%)

// 2. Compare with actual utilization
final actualUtilization = current.totalSpent / current.totalBudget;

// 3. Trigger: If Actual is > 1.3x Expected (30% buffer)
if (actualUtilization > expectedUtilization * 1.3) {
   anomalies.add(SpendingAnomaly(
     type: AnomalyType.fastBudgetDepletion,
     message: 'Budget is depleting faster than expected...',
     // ...
   ));
}
```

---

## 2. Spending Predictions (Budget Forecasting)

The "Projected Spend" figure on the dashboard is calculated using a **Weighted Linear Projection** algorithm. It answers the question: *"If I keep spending like this, how much will I have spent by the end of the month?"*

### The Formula

We don't just rely on a simple linear line (which can be inaccurate at the start of the month). We combine **Short-Term Momentum** with **Long-Term Habits**.

$$ P_{weighted} = \text{Spent}_{start} + (\text{Rate}_{weighted} \times \text{DaysRemaining}) $$

Where **Weighted Rate** is calculated as:
$$ \text{Rate}_{weighted} = (\text{Rate}_{current\_week} \times 0.7) + (\text{Rate}_{30\_day\_history} \times 0.3) $$

### The Code Implementation
Found in `SpendingInsightsService._generatePredictions`.

```dart
// 1. Calculate remaining days
final daysRemaining = daysInMonth - dayOfMonth;

// 2. Calculate Weekly Rate (Short-term momentum) -> 70% Weight
// "How fast am I spending THIS week?"
final weeklyRate = current.weekSpent / min(7, dayOfMonth);

// 3. Calculate Historical Rate (Long-term habit) -> 30% Weight
// "How much do I usually spend per day?"
final historicalRate = historical.avgDailySpend;

// 4. Combine them for the final projection
final weightedProjection = current.monthSpent +
    (weeklyRate * daysRemaining * 0.7) +      // Heavy weight on recent behavior
    (historicalRate * daysRemaining * 0.3);   // Stabilizing weight from history
```

**Scenario Walkthrough:**

Let's assume it is the **15th of the month** (15 days left).
*   **Total Spent so far:** Rs 15,000.
*   **Historical Average:** You usually spend Rs 1,000/day.
*   **This Week's Behavior:** You are on a trip and spending Rs 2,000/day.

**Step 1: Determine the Burn Rate**
*   **Short Term (70%):** $2,000 \times 0.7 = 1,400$
*   **Long Term (30%):** $1,000 \times 0.3 = 300$
*   **Weighted Rate:** $1,400 + 300 = \text{Rs } 1,700 \text{ per day}$

**Step 2: Project the Future**
*   **Remaining Days:** 15
*   **Future Spend:** $1,700 \times 15 = \text{Rs } 25,500$

**Step 3: Final Calculation**
*   **Total Projection:** $15,000 \text{ (Already Spent)} + 25,500 \text{ (Future)} = \text{Rs } 40,500$

**Why isn't it just Rs 30,000?**
A simple calculator would see you spent Rs 15k in 15 days and guess $15k \times 2 = 30k$. But Shopple knows you are currently spending *faster* (Rs 2k/day) and weights that heavily. It predicts **Rs 40.5k** instead of **Rs 30k**, giving you a much more realistic warning before you go broke.

---

## 3. Image AI Analysis (Vision System)

The product recognition feature uses **Edge AI (On-Device Machine Learning)** to identify products from camera images instantly without uploading photos to a server.

### Architecture: TFLite + Teachable Machine
We utilize a `Mobilenet` based image classification model trained via Google's Teachable Machine and deployed using TensorFlow Lite.

### Processing Pipeline
1.  **Capture:** Camera stream frame is captured.
2.  **Preprocessing:**
    *   Image is cropped to a square aspect ratio.
    *   Resized to model input dimensions (e.g., 224x224 px).
    *   Normalized (pixel values converted from 0-255 to 0.0-1.0).
3.  **Inference (The "Brain"):**
    *   The `Interpreter` runs the image through the quantized `.tflite` model.
    *   **Output:** A probability array (float32) corresponding to the labels.
4.  **Label Matching:**
    *   The index with the highest probability is mapped to `assets/ml/labels.txt`.
    *   **Threshold:** If confidence > 80%, the product is auto-detected.

### Personalization
*   **Adaptive Models:** The system is designed to support downloading custom models trained on user-specific datasets (future capability via Firebase ML Model Downloader).
*   **Privacy:** Since inference happens on the device CPU/NPU, no image data ever leaves the user's phone, ensuring complete privacy even for sensitive receipts or personal items.
