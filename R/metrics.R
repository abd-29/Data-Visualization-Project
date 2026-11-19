# Statistical model for DATA VISUALIZATION PROJECT.
# All values are fictitious. Only the Data Visualisation grade is variable.

FIXED_SUBJECTS <- data.frame(
  subject = c(
    "Traitement des signaux", "Deep Learning", "Challenge Kaggle",
    "Arbres de décision", "SVM", "Machine Learning",
    "Couplage données-modèle"
  ),
  short = c("Signaux", "Deep L.", "Kaggle", "Arbres", "SVM", "ML", "Couplage"),
  note = c(13, 15, 17, 14, 12, 16, 11),
  hours = c(16, 22, 28, 20, 18, 25, 14),
  stringsAsFactors = FALSE
)

normalize_grade <- function(value, default = 18L) {
  if (is.null(value) || length(value) != 1L) return(as.integer(default))
  number <- suppressWarnings(as.numeric(value))
  if (!is.finite(number)) return(as.integer(default))
  as.integer(max(0, min(20, round(number))))
}

subject_data <- function(grade = 18L) {
  grade <- normalize_grade(grade)
  rbind(
    FIXED_SUBJECTS,
    data.frame(
      subject = "Data Visualisation", short = "Data Viz",
      note = grade, hours = 30, stringsAsFactors = FALSE
    )
  )
}

get_mood <- function(grade) {
  if (grade >= 16L) {
    return(list(
      code = "calm", status = "Stable (pour l'instant)",
      text = "Professeur… soyez indulgent ! Mes graphiques se comportent bien pour l'instant.",
      evaluation = "Vous avez le regard d'un excellent statisticien. J'ai vérifié trois fois.",
      evaluation_short = "Mes intervalles de confiance vous remercient."
    ))
  }
  if (grade >= 10L) {
    return(list(
      code = "nervous", status = "Négociation en cours",
      text = "Une petite négociation avant de conclure, Professeur ?",
      evaluation = "Je peux vous offrir un coefficient de gentillesse. C'est parfaitement fictif.",
      evaluation_short = "Les mathématiques déposent un préavis de grève."
    ))
  }
  list(
    code = "strike", status = "Grève des statistiques",
    text = "Mes graphiques réclament un avocat. Et une seconde chance.",
    evaluation = "ERREUR : evaluation() — la note a dépassé ma capacité émotionnelle.",
    evaluation_short = "La droite de régression demande sa mutation."
  )
}

build_dashboard_payload <- function(grade = 18L) {
  grade <- normalize_grade(grade)
  dataset <- subject_data(grade)
  notes <- as.numeric(dataset$note)
  average <- mean(notes)
  validated <- sum(notes >= 10)
  model <- stats::lm(note ~ hours, data = dataset)
  x <- seq(min(dataset$hours), max(dataset$hours), length.out = 60L)
  predicted <- unname(stats::predict(model, newdata = data.frame(hours = x)))
  regression_summary <- summary(model)

  breaks <- seq(0, 20, 4)
  histogram <- as.numeric(table(cut(notes, breaks = breaks, include.lowest = TRUE)))
  sd_notes <- stats::sd(notes)
  normal_x <- seq(0, 20, length.out = 81L)
  # Normal reference scaled to the expected counts in bins of width 4.
  normal_y <- stats::dnorm(normal_x, mean = average, sd = sd_notes) * 8 * 4
  cumulative <- cumsum(notes) / seq_along(notes)

  mood <- get_mood(grade)
  subjects <- lapply(seq_len(nrow(dataset)), function(i) {
    list(
      name = dataset$subject[i], short = dataset$short[i],
      grade = as.numeric(dataset$note[i]), hours = as.numeric(dataset$hours[i]),
      editable = identical(i, nrow(dataset))
    )
  })

  list(
    grade = grade,
    average = round(average, 4),
    validated = as.integer(validated),
    passed = average >= 10,  # Simplified compensation, NOT actual university rules.
    mood = mood,
    subjects = subjects,
    regression = list(
      slope = unname(as.numeric(coef(model)[2])),
      intercept = unname(as.numeric(coef(model)[1])),
      r2 = unname(as.numeric(regression_summary$r.squared)),
      x = unname(x), y = predicted
    ),
    distribution = list(
      centers = c(2, 6, 10, 14, 18), counts = histogram,
      normal_x = normal_x, normal_y = unname(normal_y),
      mean = round(average, 4), sd = round(sd_notes, 4)
    ),
    trend = list(
      labels = dataset$short,
      values = unname(round(cumulative, 4))
    ),
    verdict = list(
      kindness = grade,
      humour = if (grade < 10) 9 else if (grade < 16) 15 else 20,
      statistical_courage = if (grade < 10) 20 else 17,
      title = if (grade < 10) "Rattrapage en bienveillance" else if (grade < 16) {
        "Admis sous négociation"
      } else "Mention très honorable",
      description = if (grade < 10) {
        "Vous avez osé mettre cette note à un dashboard doté de sentiments. Audacieux."
      } else if (grade < 16) {
        "Votre jugement est acceptable, même si mes graphiques demandent un recours."
      } else {
        "Vos qualités d'évaluateur sont désormais reconnues par cette application très objective."
      }
    )
  )
}
