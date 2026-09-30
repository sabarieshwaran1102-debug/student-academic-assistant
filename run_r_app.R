# run_r_app.R
# Script to verify/install required R packages and launch the Shiny Frontend

cat("====================================================\n")
cat(" 🎓 Starting Student Academic Assistant R Shiny App \n")
cat("====================================================\n\n")

required_packages <- c("shiny", "jsonlite", "bslib")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(paste("Installing missing package:", pkg, "\n"))
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  }
}

cat("\nLaunching Shiny App on http://127.0.0.1:3838 ... Press Ctrl+C to stop.\n\n")
shiny::runApp(".", launch.browser = TRUE, port = 3838)
