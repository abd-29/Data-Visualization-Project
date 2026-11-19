# PLEASE DON'T GRADE ME — deployable Shiny application.
# Place your animated GIFs in www/ (see README.md) and deploy the entire folder.

library(shiny)
source("R/metrics.R", local = TRUE)

mascot_path <- function(scene) {
  stem <- paste0("mascot-", scene)
  for (ext in c("gif", "webp", "png", "svg")) {
    path <- file.path("www", paste0(stem, ".", ext))
    if (file.exists(path)) return(paste0(stem, ".", ext))
  }
  stop("Missing mascot asset for scene: ", scene)
}

mascot <- function(scene, class_name = "") {
  tags$img(
    src = mascot_path(scene),
    class = paste("mascot-image", class_name),
    alt = switch(scene, `404` = "Petit dashboard qui danse",
                 `403` = "Petit dashboard inquiet", dashboard = "Étudiant inquiet"),
    draggable = "false"
  )
}

logo <- tags$div(
  class = "brand",
  tags$img(src = "graduation.svg", class = "brand-icon", alt = ""),
  tags$span("PLEASE DON'T GRADE ME")
)

primary_btn <- function(id, text, icon = NULL, class_name = "") {
  tags$button(
    id = id, type = "button", class = paste("button button-primary", class_name),
    if (!is.null(icon)) tags$span(class = "button-icon", icon),
    tags$span(text)
  )
}

secondary_btn <- function(id, text, class_name = "") {
  tags$button(id = id, type = "button", class = paste("button button-secondary", class_name), text)
}

kpi <- function(icon, label, value_id, initial, suffix = "") {
  tags$div(
    class = "kpi-card",
    tags$span(class = "kpi-icon", icon),
    tags$div(class = "kpi-body",
      tags$span(class = "kpi-label", label),
      tags$div(class = "kpi-value",
        tags$span(id = value_id, initial),
        if (nzchar(suffix)) tags$span(class = "kpi-suffix", suffix)
      )
    )
  )
}

chart_card <- function(icon, title, id, legend = NULL, description = "") {
  tags$article(
    class = "chart-card",
    tags$div(class = "chart-heading",
      tags$span(class = "chart-heading-icon", icon),
      tags$h3(title)
    ),
    if (!is.null(legend)) tags$p(class = "chart-hint", legend),
    tags$div(class = "chart-area",
      tags$svg(
        id = id, class = "chart-svg", viewBox = "0 0 600 285",
        preserveAspectRatio = "xMidYMid meet", role = "img",
        `aria-label` = description
      )
    )
  )
}

slider_block <- function(id, prefix = "") {
  tags$div(class = "slider-block",
    tags$div(class = "slider-top",
      tags$label(`for` = id, "Data Visualisation"),
      tags$span(class = "slider-number", tags$span(class = "grade-display", "18"), "/20")
    ),
    tags$input(
      id = id, class = "grade-slider", type = "range", min = "0", max = "20",
      step = "1", value = "18", `aria-label` = "Note Data Visualisation sur vingt"
    ),
    tags$div(class = "slider-limits", tags$span("0 — Grève générale"), tags$span("20 — Sérénité"))
  )
}

locked_subjects <- lapply(seq_len(nrow(FIXED_SUBJECTS)), function(i) {
  tags$div(class = "subject-row locked-row",
    tags$span(class = "subject-name", FIXED_SUBJECTS$subject[i]),
    tags$span(class = "fixed-grade", sprintf("%d / 20", FIXED_SUBJECTS$note[i])),
    tags$span(class = "sr-only", "Note fixe")
  )
})

ui <- fluidPage(
  tags$head(
    tags$meta(charset = "UTF-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$meta(name = "theme-color", content = "#0c1728"),
    tags$title("PLEASE DON'T GRADE ME — Master Science des Données"),
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    tags$script(src = "app.js")
  ),
  tags$header(class = "site-header", tags$div(class = "header-inner", logo)),
  tags$main(class = "app-content", id = "app-content",
    # 01 — False 404 page
    tags$section(id = "page-home", class = "view view-visible", `aria-label` = "Accueil : erreur 404",
      tags$div(class = "intro-card",
        tags$div(class = "error-code error-code-large", "404"),
        tags$h1("Page introuvable."),
        tags$p(class = "error-description", "Cette page semble avoir disparu..."),
        tags$div(id = "mascot-home-wrap", class = "mascot-stage mascot-stage-dancing",
          mascot("404", "mascot-home")
        ),
        tags$p(id = "home-quote", class = "character-quote", "« Moi ? Je ne sais absolument pas où elle est passée. »"),
        primary_btn("retry-button", "Réessayer", "↻", "intro-button")
      )
    ),
    # 02 — Fake 403 professor detection
    tags$section(id = "page-detected", class = "view", `aria-label` = "Professeur détecté : erreur 403",
      tags$div(class = "intro-card detection-card",
        tags$img(src = "lock.svg", class = "lock-symbol", alt = ""),
        tags$div(class = "error-code small", "403"),
        tags$p(class = "error-subtitle", "Accès refusé"),
        tags$div(class = "title-rule"),
        tags$h1(class = "detected-title", "PROFESSEUR DÉTECTÉ"),
        tags$div(class = "detection-body",
          tags$div(class = "mascot-stage mascot-stage-panicking", mascot("403", "mascot-detected")),
          tags$div(class = "detection-divider"),
          tags$div(class = "detection-copy",
            tags$h2("Oups... c'est vous, Professeur !"),
            tags$p("Pour préserver ma santé mentale et celle de mes graphiques,"),
            tags$strong("je refuse d'être noté.")
          )
        ),
        tags$div(id = "negotiation-dialog", class = "negotiation-dialog", hidden = "hidden", `aria-live` = "polite",
          tags$p(class = "dialogue-kicker", "PROTOCOLE DE NÉGOCIATION"),
          tags$p("Dashboard : « Je propose un 20/20 préventif. »"),
          tags$p("Professeur : « Je préfère voir les graphiques. »"),
          tags$p(class = "dialogue-ending", "Dashboard : « D'accord… mais soyez doux avec la régression. »")
        ),
        primary_btn("negotiate-button", "Négocier avec le dashboard", "↔", "intro-button"),
        primary_btn("enter-dashboard-button", "Accéder au bulletin", "→", "intro-button initially-hidden")
      )
    ),
    # 03 — Main dashboard (single live slider; fixed subject grades)
    tags$section(id = "page-dashboard", class = "view dashboard-view", `aria-label` = "Dashboard de notes",
      tags$div(class = "dashboard-head",
        tags$div(class = "mascot-comment",
          tags$div(class = "mascot-student", mascot("dashboard", "mascot-dashboard")),
          tags$div(class = "speech-bubble", id = "speech-text",
            "Professeur... soyez indulgent ! Mes graphiques se comportent bien pour l'instant."
          )
        ),
        tags$div(class = "dashboard-summary",
          tags$div(class = "dashboard-heading-row",
            tags$div(
              tags$h1("Mon bulletin", tags$span(class = "subdued", " (fictif) – Master Science des Données")),
              tags$p("Analyse interactive de mes résultats de semestre")
            ),
            tags$div(class = "system-status", tags$span(class = "heartbeat", "⌁"),
              tags$div(tags$span("État du dashboard"),
                tags$strong(tags$span(id = "status-dot", class = "status-dot"), tags$span(id = "status-text", "Stable (pour l'instant)"))
              )
            )
          ),
          tags$div(class = "kpi-grid",
            kpi("♜", "Moyenne générale", "average-value", "14,50", " / 20"),
            kpi("▱", "Matières validées", "validated-value", "8", " / 8"),
            kpi("✓", "Semestre (simulation)", "semester-value", "Validé")
          )
        )
      ),
      tags$div(class = "dashboard-grid",
        tags$aside(class = "grades-card",
          tags$h2(tags$span(class = "accent-icon", "✎"), "Bulletin universitaire"),
          tags$p(class = "sidebar-tip", "Sept notes officielles fictives, non modifiables."),
          locked_subjects,
          tags$div(class = "editable-subject", slider_block("grade-slider")),
          tags$div(class = "sidebar-controls",
            secondary_btn("reset-button", "↻  Réinitialiser à 18/20")
          ),
          tags$p(class = "sidebar-footnote", "Les autres matières restent figées. Seule votre note fait réagir les graphiques."),
          tags$label(class = "humour-control",
            tags$input(id = "humour-toggle", type = "checkbox", checked = "checked"),
            tags$span("Effets humoristiques")
          )
        ),
        tags$div(class = "chart-grid",
          chart_card("▥", "Notes par matière", "chart-bars",
                     description = "Notes fictives sur vingt pour huit matières"),
          chart_card("⌁", "Régression linéaire", "chart-regression",
                     description = "Relation entre les heures de révision fictives et les notes"),
          chart_card("∿", "Distribution des notes", "chart-distribution",
                     description = "Histogramme observé et courbe normale de référence"),
          chart_card("↗", "Évolution de la moyenne", "chart-trend",
                     description = "Moyenne cumulative après chaque matière")
        )
      ),
      tags$div(class = "dashboard-bottom",
        tags$p(id = "dashboard-reaction", class = "dashboard-reaction", `aria-live` = "polite",
          "Mes intervalles de confiance vous remercient."
        ),
        primary_btn("go-evaluation", "Évaluer ce dashboard", "→")
      ),
      tags$p(class = "method-note",
        "Données fictives • Coefficients égaux • Moyenne du semestre : règle simplifiée à titre de démonstration. ",
        "Les graphiques indiquent toujours les valeurs exactes ; les éléments fantaisistes sont décoratifs."
      )
    ),
    # 04 — Evaluation shares the *same* grade as the main dashboard
    tags$section(id = "page-evaluation", class = "view", `aria-label` = "Évaluation du projet",
      tags$div(class = "flow-card evaluation-card",
        tags$div(class = "section-eyebrow", "ÉTAPE 04 / ÉVALUATION"),
        tags$h1("Alors, Professeur… combien ?"),
        tags$p(class = "flow-subtitle", "Vous pouvez changer votre note. Je promets de rester professionnel. Enfin, presque."),
        tags$div(class = "evaluation-mascot", mascot("403", "mascot-eval")),
        tags$div(class = "evaluation-slider", slider_block("evaluation-grade-slider")),
        tags$div(class = "evaluation-response",
          tags$span(class = "response-heading", "RÉACTION IMMÉDIATE"),
          tags$p(id = "evaluation-message", `aria-live` = "polite", "Mes intervalles de confiance vous remercient.")
        ),
        tags$div(class = "action-row",
          secondary_btn("back-dashboard", "← Revoir mes analyses"),
          primary_btn("go-verdict", "Valider la note et voir le verdict", "→")
        )
      )
    ),
    # 05 — The dashboard grades the professor
    tags$section(id = "page-verdict", class = "view", `aria-label` = "Verdict du dashboard",
      tags$div(class = "flow-card verdict-card",
        tags$div(class = "section-eyebrow", "ÉTAPE 05 / VERDICT"),
        tags$h1("Maintenant, c'est mon tour."),
        tags$p(class = "flow-subtitle", "Vous m'avez évalué. J'ai donc décidé de vous attribuer des notes aussi."),
        tags$div(class = "verdict-seal", "🎓"),
        tags$h2(id = "verdict-title", "Mention très honorable"),
        tags$p(id = "verdict-description", "Vos qualités d'évaluateur ont été reconnues par cette application très objective."),
        tags$div(class = "verdict-rows",
          tags$div(class = "verdict-row", tags$span("Bienveillance envers les dashboards"), tags$strong(id = "kindness-score", "18/20")),
          tags$div(class = "verdict-row", tags$span("Tolérance à l'humour statistique"), tags$strong(id = "humour-score", "20/20")),
          tags$div(class = "verdict-row", tags$span("Courage face aux graphiques rebelles"), tags$strong(id = "courage-score", "17/20"))
        ),
        tags$p(class = "verdict-footnote", "Ce bulletin du professeur est entièrement humoristique. Aucune donnée personnelle n'est conservée."),
        tags$div(class = "action-row",
          secondary_btn("verdict-back", "← Retour au dashboard"),
          primary_btn("restart", "Recommencer l'expérience", "↻")
        )
      )
    )
  ),
  tags$div(id = "global-toast", class = "global-toast", role = "status", `aria-live` = "polite"),
  tags$footer(class = "site-footer", "PLEASE DON'T GRADE ME · Projet universitaire de Data Visualisation · Données fictives")
)

server <- function(input, output, session) {
  grade <- reactive(normalize_grade(input$dataviz_grade, 18L))

  observe({
    data <- build_dashboard_payload(grade())
    session$sendCustomMessage("pdgm-dashboard", data)
  })
}

shinyApp(ui = ui, server = server)
