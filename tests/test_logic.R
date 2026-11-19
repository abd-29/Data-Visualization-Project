# Run from the project root: Rscript tests/test_logic.R
source("R/metrics.R")

assert_equal <- function(actual, expected, message = "unexpected value") {
  if (!isTRUE(all.equal(actual, expected, tolerance = 1e-9))) {
    stop(message, ": actual=", toString(actual), " expected=", toString(expected))
  }
}

assert_equal(normalize_grade(NULL), 18L, "default")
assert_equal(normalize_grade(-3), 0L, "minimum clamp")
assert_equal(normalize_grade(50), 20L, "maximum clamp")
assert_equal(normalize_grade("not a note"), 18L, "invalid grade")
assert_equal(sum(FIXED_SUBJECTS$note), 98, "sum fixed subjects")

for (grade in 0:20) {
  data <- subject_data(grade)
  result <- build_dashboard_payload(grade)
  stopifnot(nrow(data) == 8L)
  assert_equal(data$note[1:7], FIXED_SUBJECTS$note, "immutable subjects")
  assert_equal(data$note[8], grade, "editable grade")
  assert_equal(result$average, (98 + grade) / 8, "mean")
  assert_equal(result$validated, 7L + as.integer(grade >= 10), "validation")
  stopifnot(result$passed)
  assert_equal(sum(result$distribution$counts), 8, "histogram total")
  assert_equal(length(result$distribution$normal_x), 81, "normal curve resolution")
  stopifnot(all(is.finite(result$distribution$normal_y)))
  stopifnot(length(result$trend$values) == 8L)
  assert_equal(tail(result$trend$values, 1), (98 + grade) / 8, "trend final")
  model <- lm(note ~ hours, data = data)
  assert_equal(result$regression$slope, unname(coef(model)[2]), "linear regression slope")
  assert_equal(result$regression$intercept, unname(coef(model)[1]), "linear regression intercept")
  stopifnot(all(is.finite(result$regression$y)))
}

assert_equal(build_dashboard_payload(0)$average, 12.25)
assert_equal(build_dashboard_payload(10)$validated, 8L)
assert_equal(build_dashboard_payload(18)$average, 14.5)
assert_equal(build_dashboard_payload(20)$average, 14.75)
stopifnot(build_dashboard_payload(9)$mood$code == "strike")
stopifnot(build_dashboard_payload(10)$mood$code == "nervous")
stopifnot(build_dashboard_payload(16)$mood$code == "calm")

cat("All statistical tests passed.\n")
