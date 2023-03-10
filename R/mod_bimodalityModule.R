#' bimodalityModule UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_bimodalityModule_ui <- function(id) {
  ns <- shiny::NS(id)

  shinydashboard::tabItem(
    tabName = 'bimodal',
    shiny::fluidRow(
      shiny::column(
        width = 3,
        shinydashboard::box(
          width = NULL,
          title = 'Parameters',
          sliderInput(
            ns("n"),
            label = "Total number of samples",
            min = 3,
            max = 5000,
            value = 32,
            step = 1
          ),

          numericInput(
            ns("alpha"),
            label =  "Significance level adjusted for multiple testing",
            value = 0.05,
            min = 0.00000001,
            max = 0.2
          ),

          selectInput(ns("dist"), label = "Distribution",
                      c(
                        "Gaussian" = "norm",
                        "Beta" = "beta",
                        "Weibull" = "weib"
                      )),

          conditionalPanel(
            condition = sprintf('input["%s"] == "norm"', ns("dist")),

            sliderInput(
              ns("mu"),
              label = "Means of Mode 1 and Mode 2",
              value = c(0,3),
              min = 0,
              max = 50
            ),

            sliderInput(
              ns("sd"),
              label = "SDs of Mode 1 and Mode 2",
              value = c(1,3),
              min = 0.01,
              max = 50
            ),
            
            sliderInput(
              ns("p"),
              label = "Proportion in mode 1",
              min = 0.01,
              max = 0.99,
              value = .5,
              step = .01
            )
          ),

         conditionalPanel(
            condition = sprintf('input["%s"] == "weib"', ns("dist")),

            sliderInput(
              ns("sp"),
              label = "Shape parameters of Mode 1 and Mode 2",
              value = c(0.5,3),
              min = 0.01,
              max = 50
            ),

            sliderInput(
              ns("sc"),
              label = "Scale parameters of Mode 1 and Mode 2",
              value = c(1,3),
              min = 0.01,
              max = 50
            ),
            
            sliderInput(
              ns("p"),
              label = "Proportion in mode 1",
              min = 0.01,
              max = 0.99,
              value = .5,
              step = .01
            )
          ),

          conditionalPanel(
            condition = sprintf('input["%s"] == "beta"', ns("dist")),
            sliderInput(
              ns("s"),
              label = "Shape parameters 1 and 2",
              value = c(0.5,0.5),
              min = 0.01,
              max = 50
            )
          ),


          ##Commented out because sigclust is being a bear
          # checkboxGroupInput("checkGroup2", label = ("Must select one or more Test"), choices = list("Hartigans' dip test"="dip","Mclust"="mclust","2-Mean cluster"="sigclust","Laplace"="isbimo","Mouse Trap"="mt"),selected="dip"),
          #

          checkboxGroupInput(
            ns("checkGroup2"),
            label = ("Must select one or more Test"),
            choices = list(
              "Hartigans' dip test" = "dip",
              "Mclust" = "mclust",
              "Laplace" = "isbimo",
              "Mouse Trap" = "mt"
            ),
            selected = "dip"
          ),

          numericInput(
            ns("nsim"),
            label = "Number of simulations",
            min = 10,
            max = 5000,
            value = 10
          ),

          shiny::h5("To save parameters, enter file name and click the Download button:"),

          shiny::textInput(
            inputId = ns("filename"),
            label = "File Name",
            value = "params1"
          ),

          shinyWidgets::downloadBttn(
            outputId = ns("downloadParams"),
            label = "Download",
            style = "gradient",
            color = "primary",
            size = "sm"
          )
        ) # END box
      ),
      # END column

      shiny::column(
        width = 9,
        shinydashboard::box(width = NULL,
                            title = 'Detecting Bimodality',
                            # verbatimTextOutput(ns('description')),
                            plotly::plotlyOutput(ns("pplt")),
                            DT::dataTableOutput(ns("paramsTable"))
                            ) # END box
      ) # END column
    ) # END fluidRow
  ) # END tabItem
}

#' bimodalityModule Server Functions
#'
#' @noRd
mod_bimodalityModule_server <- function(id) {
  moduleServer(id,
               function(input, output, session) {
                 # observeEvent(input$dist, {
                 #   output$inputdist = renderUI({
                 #     input_list <- if(input$dist == "norm"){
                 #       list(
                 #         numericInput(ns("mu1"),
                 #                      label="Mean of mode 1", value=0, min = NA, max = NA),
                 #         numericInput(ns("sd1"),
                 #                      label="SD of mode 1", value=1, min = NA, max = NA),
                 #         numericInput(ns("mu2"),
                 #                      label="Mean of mode 2", value=3, min = NA, max = NA),
                 #         numericInput(ns("sd2"),
                 #                      label="SD of mode 2", value=1, min = NA, max = NA),
                 #         sliderInput(ns("p"),
                 #                     label = "Proportion in mode 1",min = 0.01, max = 0.99, value = .5, step = .01))
                 #     } else {
                 #       if(input$dist == "beta"){
                 #         list(
                 #           numericInput(ns("s1"),
                 #                        label="Shape parameter 1", value=.5, min = NA, max = NA),
                 #           numericInput(ns("s2"),
                 #                        label="Shape parameter 2", value=.5, min = NA, max = NA))}
                 #     }
                 #     do.call(tagList, input_list)
                 #   })
                 # })

                 ss <- reactive({
                   if (input$dist == "norm") {
                     calcs =  reshape2::melt(as.data.frame(
                       bifurcatoR::est_pow(
                         input$n,
                         input$alpha,
                         input$nsim,
                         input$dist,
                         list(
                           p = input$p,
                           mu1 = input$mu[1],
                           sd1 = input$sd[1],
                           mu2 = input$mu[2],
                           sd2 = input$sd[2]
                         ),
                         tests = input$checkGroup2
                       )
                     ), id.vars = c("N", "Test"))

                     dens.plot = data.frame(var = c(
                       rnorm(ceiling(input$p * 2000), input$mu[1], input$sd[1]),
                       rnorm(ceiling((1 - input$p) * 2000), input$mu[2], input$sd[2])
                     ))


                   } else {
                     if (input$dist == "beta") {
                       dens.plot =  data.frame(var = rbeta(2000, input$s[1], input$s[2]))
                       calcs =  reshape2::melt(as.data.frame(
                         bifurcatoR::est_pow(
                           input$n,
                           input$alpha,
                           input$nsim,
                           input$dist,
                           list(s1 = input$s[1], s2 = input$s[2]),
                           tests = input$checkGroup2
                         )
                       ), id.vars = c("N", "Test"))
                     } else {
                      if (input$dist == "weib") {
                       calcs =  reshape2::melt(as.data.frame(
                           bifurcatoR::est_pow(
                            input$n,
                            input$alpha,
                            input$nsim,
                            input$dist,
                            list(
                              p = input$p,
                              sp1 = input$sp[1],
                              sc1 = input$sc[1],
                              sp2 = input$sp[2],
                              sc2 = input$sc[2]
                             ),
                            tests = input$checkGroup2
                           )
                         ), id.vars = c("N", "Test"))

                        dens.plot = data.frame(var = c(
                        rweibull(ceiling(input$p * 2000), input$sp[1], input$sc[1]),
                        rweibull(ceiling((1 - input$p) * 2000), input$sp[2], input$sc[2])
                      ))
                      }
                    }
                   }
                   list(dens.plot = dens.plot, calcs = calcs)
                 })


                 output$pplt <- plotly::renderPlotly({
                   p1 = plotly::ggplotly(
                     ggplot2::ggplot() +
                       ggplot2::geom_density(data = ss()[["dens.plot"]], ggplot2::aes(x = var)) +
                       ggplot2::theme_classic(14) +
                       ggplot2::ylab("Population density") +
                       ggplot2::xlab("Modes") +
                       ggplot2::theme(legend.text = ggplot2::element_text(10))
                   )
                   fig1 = plotly::ggplotly(p1)

                   p2 = plotly::ggplotly(
                     ggplot2::ggplot(data = ss()[["calcs"]], ggplot2::aes(
                       x = Test, y = value, color = variable
                     )) +
                       ggplot2::geom_point(position = ggplot2::position_dodge(width = .25)) +
                       ggplot2::theme_classic(14) +
                       ggplot2::ylab("Probability") +
                       ggplot2::xlab("Test") +
                       ggplot2::theme(
                         legend.title = ggplot2::element_blank(),
                         legend.text = ggplot2::element_text(10),
                         axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
                       ) +
                       ggplot2::scale_color_manual(values = c("black", "red")) +
                       ggplot2::coord_cartesian(ylim = c(-.01, 1.01))
                   )
                   fig2 = plotly::ggplotly(p2)

                   plotly::subplot(fig1,
                           fig2,
                           nrows = 1,
                           margin = c(0.02, 0.02, .21, .21))

                 })

                 paramsTable <- shiny::reactive({

                   calcOutput <- ss()[['calcs']]
                   # calcOutput$Row <- 1:nrow(calcOutput)

                   results <- data.frame(
                     Distribution = input$dist,
                     nSim = input$nsim
                   )

                   calcOutput <- tidyr::pivot_wider(calcOutput, names_from = c('Test', 'variable'), values_from = 'value')
                   tidyr::expand_grid(results, calcOutput)
                 })

                 output$paramsTable <- DT::renderDataTable( paramsTable() )

                 output$downloadParams <- shiny::downloadHandler(

                   filename = function() {
                     paste0(input$filename, ".csv")
                   },

                   content = function(file) {
                     write.csv(paramsTable(), file, row.names = FALSE)
                   }
                 )

               })
}

## To be copied in the UI
# mod_bimodalityModule_ui("bimodalityModule_1")

## To be copied in the server
# mod_bimodalityModule_server("bimodalityModule_1")
