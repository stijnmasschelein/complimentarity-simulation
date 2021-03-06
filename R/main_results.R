# source("R/prettify_functions.R")
source("R/parameters.R")
library(tidyverse)
sim = readRDS("simulated_data/main_simulation.Rds")
dat = tbl_df(sim) %>%
  mutate(obs = map_dbl(obs, ~ .x[[1]]),
         rate = map_dbl(rate, ~ .x[[1]]),
         optim = 1/rate)  

#' plot
library(ggplot2) 
library(ggthemes)
library(cowplot)

#' table
library(xtable)
library(kableExtra)

# Old table ----

table = dat %>%
  group_by(label, g1 = unlist(map(g1, 2)), 
           b2 = unlist(map(b2, 1)), optim) %>%
    summarise(type1 = round(sum(pvalue < 0.05)/sim_params$nsim, 2),
              power = round(sum(pvalue < 0.05 & coefficient > 0)/sim_params$nsim, 2)) %>%
    ungroup() %>% 
    mutate(percentage = ifelse(b2 != 0, power, type1),
           statistic = ifelse(b2 != 0, "power", "type I")) %>%
    select(-c(type1, power, b2)) %>%
    spread(optim, percentage) %>%
    arrange(statistic, label, g1) %>%
    rename(`$\\gamma_2$` = g1,
           specification = label)

# print(xtable(table,
#              type = "pdf",
#              label = "main-table",
#              caption = "Type I error rates and power for the demand 
#              and performance function approaches at different
#              levels optimality: 2, 4, 8, 16, 32, 64. The 
#              parameters are the same as in Figure
#              \\ref{main}."),
#       size = "\\footnotesize",
#       include.rownames = FALSE,
#       sanitize.text.function = force,
#       comment = FALSE,
#       file = "tex/main_table.tex"
# )

# New table ----

footnote = "Type I error rates and power for the demand 
            and performance specifications at different
            levels optimality: 2, 4, 8, 16, 32, 64. The
            parameters are the same as in Figure
            \\\\ref{main}."

table %>% select(-statistic) %>%
  kable(format = "latex", booktabs = T, linesep = "", 
        escape = F, digits = 2,
        label = "main-table", 
        caption = "Power and Type I Error Rate for Baseline Simulation") %>%
  pack_rows("Power", 1, 12, latex_align = "c") %>%
  pack_rows("Type I", 13, 24, latex_align = "c") %>%
  add_header_above(c(" " = 1, " "  = 1, 
                     "Level of Optimality" = 6)) %>%
  kable_styling(font_size = 9) %>%
  footnote(
    general = footnote,         
    escape = FALSE, threeparttable = TRUE) %>%
  cat(., file = "tex/main_table.tex")   

# New plot ----

dat_plot_new = 
  filter(dat,
         unlist(map(g1, 2)) != 0.33) %>%
  mutate(optim_fact = paste(optim),
         g1_fact = paste("gamma[2] ==", map(g1, 2)),
         b2_fact = paste(map(b2, 1))) %>%
  arrange(optim) %>%
  mutate(optim_fact = fct_relevel(optim_fact, unique(optim_fact)),
         g1_fact = fct_relevel(g1_fact, c("gamma[2] == 0")))

plot_null = (ggplot(filter(dat_plot_new, unlist(map(b2, 1)) == 0),
                    aes(y = stat, x = optim_fact))
         + geom_tufteboxplot()
         + theme_cowplot(font_size = 12)
         + facet_grid(rows = vars(label),
                      cols = vars(g1_fact),
                      labeller = label_parsed)
         + geom_hline(yintercept = tint, linetype = 3, alpha = .25)
         + geom_hline(yintercept = 0, linetype = 4, alpha = .25)
         + geom_hline(yintercept = -tint, linetype = 3, alpha = .25)
         + scale_y_continuous(breaks = scales::pretty_breaks(4))
         + ggtitle("Null Effect")
         + labs(x = "level of optimality", y = "t-statistic")
         + theme(strip.text.x = element_text(angle = 0, size = 8),
                 strip.text.y = element_text(angle = 0),
                 strip.background = NULL)
)

plot_true = (ggplot(filter(dat_plot_new, unlist(map(b2, 1)) == 0.25),
                    aes(y = stat, x = optim_fact))
         + geom_tufteboxplot()
         + theme_cowplot(font_size = 12)
         + facet_grid(rows = vars(label),
                      cols = vars(g1_fact),
                      labeller = label_parsed)
         + geom_hline(yintercept = tint, linetype = 3, alpha = .25)
         + geom_hline(yintercept = 0, linetype = 4, alpha = .25)
         + geom_hline(yintercept = -tint, linetype = 3, alpha = .25)
         + scale_y_continuous(breaks = scales::pretty_breaks(4))
         + ggtitle("True Effect")
         + labs(y = "t-statistic", x = NULL)
         + theme(strip.text.x = element_text(angle = 0, size = 8),
                 strip.text.y = element_text(angle = 0),
                 strip.background = NULL)
)

new_plot = plot_grid(plot_true, plot_null, labels = "AUTO",
                     ncol = 1)
save_plot("figure-latex/main_new_plot.pdf", plot = new_plot,
          base_height = 6, base_width = 9,
          dpi = 600)
                   
