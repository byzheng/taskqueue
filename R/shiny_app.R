
#' Launch Shiny App for Monitoring Projects
#'
#' Starts an interactive Shiny application to monitor task progress and
#' runtime statistics for taskqueue projects.
#'
#' @return Does not return while the app is running. Stops when the app is closed.
#'
#' @details
#' The Shiny app provides:
#' \itemize{
#'   \item Project selector dropdown
#'   \item Real-time task status table (updates every 5 seconds)
#'   \item Runtime distribution histogram for completed tasks
#' }
#'
#' Useful for monitoring long-running projects and identifying performance issues.
#'
#' @seealso \code{\link{project_status}}, \code{\link{task_status}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Launch monitoring app
#' shiny_app()
#' }
#' @export
shiny_app <- function() {
    projects <- project_list()
    ui <- shiny::fluidPage(
        shiny::selectInput("project", "Project:",
                    projects$name),
        shiny::tableOutput("status"),
        shiny::plotOutput("runtime", height=600
        )
    )

    server <- function(input, output, session) {
        all_task_status <- shiny::reactive({
            # invalidate 6 hrs later
            shiny::invalidateLater(1000 * 5)
            prj <- input$project
            res <- task_status(prj)
            res$project <- prj
            res <- res[,c("project", "status", "count", "ratio")]
            res
        })

        tasks_runtime <- shiny::reactive({
            # invalidate 6 hrs later
            shiny::invalidateLater(1000 * 5)
            prj <- input$project
            res <- task_get(project = prj, status = "finished", limit = 10000000)
            res[!is.na(res$runtime),]
        })


        output$status <- shiny::renderTable({
           s <- all_task_status()
           s
        })
        output$runtime <- shiny::renderPlot({
            res <- tasks_runtime()
            if (nrow(res) == 0) {
                return(invisible())
            }
            ggplot2::ggplot(res) +
                ggplot2::geom_point(ggplot2::aes(.data$start, .data$runtime)) +
                ggplot2::theme_bw() +
                ggplot2::ylab("Runtime (s)") +
                ggplot2::xlab("")
        })
    }


    shiny::shinyApp(ui, server)
}
