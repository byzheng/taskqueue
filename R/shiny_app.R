
shiny_app <- function() {
    projects <- project_list()
    ui <- shiny::fluidPage(
        shiny::tableOutput("status")
    )

    server <- function(input, output, session) {
        all_task_status <- shiny::reactive({
            # invalidate 6 hrs later
            shiny::invalidateLater(1000 * 5)

            con <- db_connect()
            on.exit(db_disconnect(con), add = TRUE)
            projects <- project_list(con = con)
            res <- list()
            for (i in seq(along = projects$name)) {
                res_i <- task_status(projects$name[i], con = con)
                res_i$project <- projects$name[i]
                res[[i]] <- res_i
            }
            res <- do.call(rbind, res)
            res <- res[,c("project", "status", "count", "ratio")]
            res
        })

        output$status <- shiny::renderTable({
           s <- all_task_status()
           s
        })
    }


    shiny::shinyApp(ui, server)
}
