source("R/parameters.R")
library(tidyverse)
sim = readRDS("simulated_data/delta_simulation.Rds")
main = readRDS("simulated_data/main_simulation.Rds")
dat_main = tbl_df(main) %>%
  filter(g1 %in% data_params$g1[2:3], rate %in% data_params$rate[c(1, 3, 5)])
dat = tbl_df(sim) %>%
  bind_rows(dat_main) %>%
  unnest(obs, rate) %>%
  mutate(optim = 1/rate)

dat_plot = 
  mutate(dat, 
         optim_fact = paste("O ==", optim),
         g1_fact = paste("gamma[2] ==", map(g1, 2)),
         d_fact = paste("delta[i] ==", map(d, 1)),
         b2_fact = paste(map(b2, 1))) %>%
  arrange(optim) %>%
  mutate(optim_fact = fct_relevel(optim_fact, unique(optim_fact)))

#' plot
library(ggplot2) 
library(ggthemes)
library(cowplot)

plot = (ggplot(dat_plot, aes(y = stat, x = b2_fact))
         + geom_tufteboxplot()
         + theme_cowplot(font_size = 12)
         + facet_grid(rows = vars(label),
                      cols = vars(optim_fact, d_fact, g1_fact),
                      labeller = label_parsed)
         + geom_hline(yintercept = tint, linetype = 3, alpha = .25)
         + geom_hline(yintercept = 0, linetype = 4, alpha = .25)
         + geom_hline(yintercept = -tint, linetype = 3, alpha = .25)
         + labs(x = expression(beta[12]), y = "t-statistic")
         + theme(strip.text.x = element_text(angle = 0, size = 8),
                 strip.text.y = element_text(angle = 0),
                 strip.background = NULL)
)

save_plot("figure-latex/delta_plot.pdf", plot = plot, 
          base_height = 6, base_width = 12, dpi = 600)


#' table
library(xtable)

table = dat %>%
  filter(label %in% c("demand", "performance~1"), 
         unlist(map(g1, 2)) > 0) %>%
  group_by(label, g1 = unlist(map(g1, 2)), d = unlist(map(d, 1)), 
           b2 = unlist(map(b2, 1)), optim) %>%
    summarise(type1 = round(sum(pvalue < 0.05) / sim_params$nsim, 2),
              power = round(sum(pvalue < 0.05 & coefficient > 0) / sim_params$nsim, 2)) %>%
    ungroup() %>%
    mutate(percentage = ifelse(b2 != 0, power, type1),
           statistic = ifelse(b2 != 0, "power", "type I")) %>%
    select(-c(type1, power, b2)) %>%
    spread(optim, percentage) %>%
    arrange(desc(statistic), label, g1) %>%
    rename(`$\\gamma_2$` = g1,
           `$\\delta_i$` = d,
           specification = label)
    
print(xtable(table,
             type = "pdf",
             label = "delta-table",
             caption = "Type I error rates and power for the \\emph{demand} and
             \\emph{performance 1} specification at different levels optimality: 
             2, 8, 32. The parameters are the same as in Figure \\ref{delta}.
             Only the results for $\\gamma_{2} = 0.33$ are reported"),
      size = "\\footnotesize",
      include.rownames = FALSE,
      sanitize.text.function = force,
      comment = FALSE,
      file = "tex/delta_table.tex"
)
