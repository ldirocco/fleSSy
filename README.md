# fleSSy

`fleSSy` is an R function designed to generate **synthetic survival data**.


## Usage

### Preprocessing Requirements

Before using `flessy`, your dataset must meet the following conditions:

- It must contain two essential columns:
  - `time`: numeric, representing time-to-event.
  - `status`: binary (1 = event, 0 = censored).
- All categorical variables **must be encoded as factors**.
- Variables involved in the synthesis or survival modeling should not contain missing values (unless handled via `mice` internally).
- The dataset should be loaded as a `data.frame`.

### Example

```r
# Load the data
data <- read_csv("SurvivalCovid.csv")[, 3:7]

# Convert categorical variables to factors
data$sex <- as.factor(data$sex)
data$ph.ecog <- as.factor(data$ph.ecog)

# Generate synthetic survival data
output <- flessy(
  data = data,
  n = 100,
  pred = c(3, 4, 5),
  seq = c(3, 4, 5),
  methods = "parametric"
)
```

## Function: `flessy()`

### Arguments

| Argument       | Type                     | Description |
|----------------|--------------------------|-------------|
| `data`         | `data.frame`             | Dataset containing `time`, `status`, and covariates. |
| `n`            | `integer`                | Number of synthetic individuals to generate. |
| `pred`         | `numeric` or `character` | Variables used to predict survival time. Can be indices or names. |
| `seq`          | `numeric` or `character` | Variables to be synthesized (visit sequence). Can be indices or names. |
| `methods`      | `character` or `list`    | Synthesis method(s) for variables in `seq`. See below for details. |
| `dropout`      | `character` or `NULL`    | Optional name of dropout variable. If `NULL`, a column of 0s is added. |
| `entry_date`   | `character` or `NULL`    | Optional name of entry date variable. If `NULL`, a column of 0s is added. |
| `start`        | _reserved_               | Currently unused. |
| `knots`        | `numeric` or `NULL`      | Optional vector of knot positions for the survival spline model. |
| `seed`         | `integer`                | Random seed for reproducibility (default: 134). |
| `exclude_pred` | `logical`                | If `TRUE`, exclude predictors (`pred`) from final synthetic dataset. |
| `r`            | `logical`                | If `TRUE`, rounds survival times to the nearest integer. |

### Default Imputation Methods (`methods` argument)

The default imputation method for each variable in `seq` follows the same logic as `synthpop::syn()`:

- If the variable is **numeric** → `"normrank"`
- If the variable is a **factor with 2 levels** → `"logreg"`
- If the variable is a **factor with more than 2 levels and ordered** → `"polr"`
- If the variable is a **factor with more than 2 levels and unordered** → `"polyreg"`

You can override defaults by supplying a character vector or named list of methods corresponding to the variables in `seq`. Example:

```r
methods = list(
  age = "normrank",
  sex = "logreg",
  ph.ecog = "polyreg"
)
```

### Custom Methods

In addition to the standard methods provided by `synthpop`, `flessy` supports the use of **custom imputation methods** for synthesizing specific variables.

The following custom methods are implemented and available in the `syn_methods.R` script:

- `syn.lasso.norm`: Uses **LASSO regression** for continuous (numeric) variables.
- `syn.lasso.logreg`: Uses **LASSO logistic regression** for binary (two-level factor) variables.
- `syn.lda`: Uses **Linear Discriminant Analysis (LDA)** for categorical variables with more than two levels.

Each custom method is compatible with the `synthpop::syn()` function, and must follow its expected method structure. They can be passed via the `methods` argument.

### 📤 Output

The `flessy()` function returns a `data.frame` with `n` rows corresponding to the synthetic individuals generated. The output includes:

- The simulated survival time variable `time`.
- The survival event indicator variable `status`.
- Synthesized covariates as specified by the `seq` argument.



# Using `flessy()` from Python

You can call the `flessy()` R function directly from Python using the `rpy2` package. This is useful if you want to integrate synthetic survival data generation into a Python workflow.

### Setup

First, install `rpy2` if you haven't already:

```bash
pip install rpy2
Make sure R and all required R packages (flexsurv, synthpop, etc.) are installed and your flessy() function and dependencies are sourced in R.

## 🚀 Example Usage (Python)

You can use the `flessy()` R function from Python via the `rpy2` package. Below is a simple example:

```python
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
pandas2ri.activate()

# Source R scripts
robjects.r('source("syn_methods.R")')
robjects.r('source("flessy.R")')

# Load data and preprocess in R
robjects.r('''
library(readr)
data <- read_csv("SurvivalCovid.csv")[, 3:7]
data$sex <- as.factor(data$sex)
data$ph.ecog <- as.factor(data$ph.ecog)
''')

# Call flessy() from R
flessy = robjects.globalenv['flessy']
synthetic_data = flessy(
    robjects.r['data'],     # data frame
    100,                    # number of synthetic samples
    robjects.r('c(3,4,5)'), # pred columns
    robjects.r('c(3,4,5)')  # seq columns
)

# Convert to pandas DataFrame
df_synth = pandas2ri.rpy2py(synthetic_data)

print(df_synth.head())
```


### Notes
- Adjust the source() paths according to where your R scripts are stored.

- Ensure your R environment has all dependencies installed.

- This approach requires familiarity with both R and Python environments.


