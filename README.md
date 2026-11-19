# DATA VISUALIZATION PROJECT 🎓

An interactive R Shiny dashboard that gets nervous when a professor grades it.

**DATA VISUALIZATION PROJECT** is a university project combining statistical analysis, interactive charts, and humor. The dashboard reacts to the professor's evaluation while keeping its statistical calculations accurate.

## Features

- Interactive introduction with fake 404 and 403 error pages.
- Animated characters and humorous reactions.
- Academic dashboard with eight subjects and fictional grades.
- Interactive slider to evaluate Data Visualization (0–20).
- Real-time updates of statistical indicators and charts.
- Final evaluation where the dashboard grades the professor.
- Responsive dark-mode interface.

## Data Visualization

The dashboard includes four interactive charts:

1. **Grades by subject** — Comparison of academic results.
2. **Linear regression** — Relationship between study time and grades.
3. **Grade distribution** — Histogram and normal distribution.
4. **Average evolution** — Cumulative average across subjects.

Only the Data Visualization grade can be modified. The other seven grades remain fixed.

All data is fictional.

## Tech Stack

- **R Shiny** — Application and reactive calculations
- **HTML / CSS** — Interface and responsive design
- **JavaScript** — Animations and interactions
- **SVG** — Charts and visual elements
- **shinyapps.io** — Hosting
- **GitHub Actions** — CI/CD

## Getting Started

**1. Clone the repository**

```bash
git clone <repository-url>
cd data-visualization-project
```

**2. Install R dependencies**

```r
install.packages("shiny")
```

**3. Run the application**

```r
shiny::runApp()
```

## Custom Animations

Custom GIF animations can be placed in the `www/` directory:

- `mascot-404.gif`
- `mascot-403.gif`
- `mascot-dashboard.gif`

Default SVG characters are provided as fallbacks.

## Testing

Run the statistical tests:

```bash
Rscript tests/test_logic.R
```

## Deployment

The application is designed for deployment on **shinyapps.io**.

GitHub Actions can automatically run checks on each push and deploy the application when changes are pushed to `main`, provided the CI/CD workflow and repository secrets are configured.

Required GitHub Secrets:

- `SHINYAPPS_ACCOUNT`
- `SHINYAPPS_TOKEN`
- `SHINYAPPS_SECRET`

## Disclaimer

This project is intended for educational and entertainment purposes. All grades and academic records are fictional. Statistical calculations remain accurate, while visual disruptions are intentional humorous effects.

---

**Built with R Shiny — Please don't grade me too harshly. 🎓**