#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
#


# Load all libraries ------------------------------------------------------------------------
library(shiny)
library(shinythemes)
library(tidyverse)
library(colourpicker)

source("covid_data_load.R") ## This line runs the Rscript "covid_data_load.R", which is expected to be in the same directory as this shiny app file!
# The variables defined in `covid_data_load.R` are how fully accessible in this shiny app script!!

# UI --------------------------------
ui <- shinyUI(
        navbarPage(theme = shinytheme("journal"), 
                   title = "COVID-19 Super Tracker", 
            
            ## All UI for NYT goes in here:
            tabPanel("NYT data visualization", ## do not change this name
            
                    # All user-provided input for NYT goes in here:
                    sidebarPanel(
                        
                        colourpicker::colourInput("nyt_color_cases", "Color for plotting COVID cases:", value = "cyan4"),
                        colourpicker::colourInput("nyt_color_deaths", "Color for plotting COVID deaths:", value = "dodgerblue"),
                        #Selection box for state
                        selectInput("which_state_nyt",  ##input$which_state
                                    "Select which state to plot:",
                                    choices = usa_states,
                                    selected = "New Jersey"), ##this sets the default value
                        
                        #Button for county faceting
                        radioButtons("facet_county_nyt",
                                     "Show by individual counties:",
                                     choices = c("Yes", "No"),
                                     selected = "No"),
                        
                        #Button for y axis
                        radioButtons("y_scale_nyt",
                                    "Y-axis scale:",
                                    choices = c("Linear","Log"),
                                    selected = "Linear"),
                        
                        #Selection box for plot background
                        selectInput("which_theme_nyt",
                                    "Choose plot background:",
                                    choices = c("Minimal", "Grey", "Dark", "Linedraw"),
                                    selected = "Minimal")
                       
                        
                    ), # closes NYT sidebarPanel. Note: we DO need a comma here, since the next line opens a new function     
                    
                    # All output for NYT goes in here:
                    mainPanel(
                        plotOutput("nyt_plot", height = "500px") ##this alters plot height
                    ) # closes NYT mainPanel. Note: we DO NOT use a comma here, since the next line closes a previous function  
            ), # closes tabPanel for NYT data
            
            
            ## All UI for JHU goes in here:
            tabPanel("JHU data visualization", ## do not change this name
                     
                     # All user-provided input for JHU goes in here:
                     sidebarPanel(

                         colourpicker::colourInput("jhu_color_cases", "Color for plotting COVID cases:", value = "orange2"),
                         colourpicker::colourInput("jhu_color_deaths", "Color for plotting COVID deaths:", value = "mediumvioletred"),
                         
                         #Selection box for country or region
                         selectInput("which_co_reg",  ##input$which_co_reg
                                     "Select which country or region to plot:",
                                     choices = world_countries_regions,
                                     selected = "Germany"), #default value for country
                         
                         #Button for scale of y-axis
                         radioButtons("y_scale_jhu",
                                      "Y-axis scale:",
                                      choices = c("Linear","Log"),
                                      selected = "Linear"),
                         
                         #Selection box for plot theme
                         selectInput("which_theme_jhu",
                                     "Choose plot background:",
                                     choices = c("Minimal", "Grey", "Dark", "Linedraw"),
                                     selected = "Minimal")
                         
                         
                     ), # closes JHU sidebarPanel     
                     
                     # All output for JHU goes in here:
                     mainPanel(
                        plotOutput("jhu_plot", height = "500px") ###plot height for shiny output
                     ) # closes JHU mainPanel     
            ) # closes tabPanel for JHU data
    ) # closes navbarPage
) # closes shinyUI

# Server --------------------------------
server <- function(input, output, session) {

    ## PROTIP!! Don't forget, all reactives and outputs are enclosed in ({}). Not just parantheses or curly braces, but BOTH! Parentheses on the outside.
    
    

    
    ## All server logic for NYT goes here ------------------------------------------
    
    ## Define a reactive for subsetting the NYT data
    nyt_data_subset <- reactive({
        
        nyt_data %>%
            filter(state == input$which_state_nyt) -> nyt_state
        
        ##Option "no" for facet by county
        if (input$facet_county_nyt == "No"){
            ##combine county data to get single point per day for cases and deaths
            nyt_state %>%
                group_by(date, covid_type) %>%
                summarize(y = sum(cumulative_number)) -> final_nyt_state
        }
        
        ##Option "yes" for facet by county
        if (input$facet_county_nyt == "Yes"){
            nyt_state %>%
                ##rename the y axis variable so we can call it just "y"
                rename(y = cumulative_number) -> final_nyt_state
        }
        
        #print plot 
        final_nyt_state
        
    })
    
    ## Define your renderPlot({}) for NYT panel that plots the reactive variable. ALL PLOTTING logic goes here.
    output$nyt_plot <- renderPlot({
        
        nyt_data_subset() %>%
            ggplot(aes(x = date, y = y, color = covid_type, group = covid_type)) +
            #line graph with point and line
            geom_point() +
            geom_line() +
            #change name of color coding legend and set default values
            scale_color_manual(name = "Case Type", values = c(input$nyt_color_cases, input$nyt_color_deaths)) +
            #clean up axis labels
            xlab("Date") +
            ylab("Number of Cases or Deaths") +
            #program title and add subtitle
            labs(title = paste(input$which_state_nyt, "Cases and Deaths"), subtitle = "Live Data from The New York Times") -> nyt_subset_plot
        
        ##Corresponds to input$y_scale choice
        if(input$y_scale_nyt == "Log") {
            nyt_subset_plot <- nyt_subset_plot + scale_y_log10()
        }
    ##Corresponds to input$facet_county choice
        if (input$facet_county_nyt == "Yes") nyt_subset_plot <- nyt_subset_plot + facet_wrap(~county)
    
    ##Corresponds to input$which_theme choice
    ##Watch capital letters for theme selection
    if (input$which_theme_nyt == "Minimal") nyt_subset_plot <- nyt_subset_plot + theme_minimal()
    
    if (input$which_theme_nyt == "Grey") nyt_subset_plot <- nyt_subset_plot + theme_grey()
    
    if (input$which_theme_nyt == "Dark") nyt_subset_plot <- nyt_subset_plot + theme_dark() 
    
    if (input$which_theme_nyt == "Linedraw") nyt_subset_plot <- nyt_subset_plot + theme_linedraw()
    
    
    ###Return the plot to be plotted
    nyt_subset_plot + theme(legend.position = "bottom")
    
    })
    
    ## All server logic for JHU goes here ------------------------------------------

    
    ## Define a reactive for subsetting the JHU data
    jhu_data_subset <- reactive({
        
        jhu_data %>%
            ##main category is country or region
            ##we can facet by province or state later
            filter(country_or_region == input$which_co_reg) -> jhu_co_reg
        
    })
    
    
    ## Define your renderPlot({}) for JHU panel that plots the reactive variable. ALL PLOTTING logic goes here.
    output$jhu_plot <- renderPlot({
        
        jhu_data_subset() %>%
            #we already defined y in our reactive, so we can use it as our y-axis
            #group and color by similar things to NYT data
            #y is not defined here so we use cumulative_number instead
            ggplot(aes(x = date, y = cumulative_number, color = covid_type, group = covid_type)) +
            #line graph with geom point and line
            geom_point() +
            geom_line() +
            #rename color coding legend and set default color values
            scale_color_manual(name = "Case Type", values = c(input$jhu_color_cases, input$jhu_color_deaths)) +
            xlab("Date") + 
            ylab("Number of Cases or Deaths") +
            labs(title = paste(input$which_co_reg, "Cases and Deaths"), subtitle = "Live Data from Johns Hopkins University") -> jhu_subset_plot
       
        
        ##Corresponds to input$y_scale_jhu
        if(input$y_scale_jhu == "Log") {
            jhu_subset_plot <- jhu_subset_plot + scale_y_log10()
        }
        
        
        ##Corresponds to input$which_theme_jhu
        if (input$which_theme_jhu == "Minimal") jhu_subset_plot <- jhu_subset_plot + theme_minimal()
        
        if (input$which_theme_jhu == "Grey") jhu_subset_plot <- jhu_subset_plot + theme_grey()
        
        if (input$which_theme_jhu == "Dark") jhu_subset_plot <- jhu_subset_plot + theme_dark() 
        
        if (input$which_theme_jhu == "Linedraw") jhu_subset_plot <- jhu_subset_plot + theme_linedraw()
        
        
        ###Return the plot to be plotted
        jhu_subset_plot + theme(legend.position = "bottom")
        
    })
    
}  ##This closes the server in line 101!





# Do not touch below this line! ----------------------------------
shinyApp(ui = ui, server = server)
