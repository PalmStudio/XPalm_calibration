library(sensitivity, dplyr, plotly)

df_raw_params <- read.csv("2-results/xpalm_parameters.csv", sep = ";")

df_raw_params <- df_raw_params[!is.na(as.numeric(df_raw_params$low_boundary)) & !is.na(as.numeric(df_raw_params$high_boundary)), ]

colnames(df_raw_params) <- c("variable", "value", "low_boundary", "high_boundary")

Pvar <- df_raw_params[, c("variable", "value", "low_boundary", "high_boundary")]
rownames(Pvar) <- Pvar$variable

parameters <- as.character(Pvar$variable) #parameter list

nFact <- parameters #number of factor

r <- 30 #number of Morris trajectories

binf <- Pvar$low_boundary; names(binf) <- parameters #inf limit
bsup <- Pvar$high_boundary; names(bsup) <- parameters #sup limit

Q <- 10
step <- 2

set.seed(1)
RNGkind(kind = "L'Ecuyer-CMRG")

etude.morris <- morris(
    model = NULL,
    factors = nFact,
    r = r,
    design = list(type = "oat", levels = Q, grid.jump = step),
    binf = binf,
    bsup = bsup,
    scale = TRUE
)

planMorris <- etude.morris$X

plot(as.data.frame(planMorris))

visuTraj <- as.data.frame(planMorris) %>%
    mutate(sim = row_number()) %>%
    mutate(trajectory = as.factor(sim %/% length(parameters)))

# Pick 3 parameters to visualize (change as needed)
selected_vars <- parameters[1:3]

plotly::plot_ly(
  visuTraj,
  x = ~get(selected_vars[1]),
  y = ~get(selected_vars[2]),
  z = ~get(selected_vars[3]),
  type = "scatter3d",
  mode = "lines+markers",
  color = ~trajectory,
  line = list(width = 4)
)

### run simulations of the model on the Morris plan (from here)
outputMorris=planMorris%>%
  as.data.frame()%>%
  mutate(y=simple.model(a,b,c,d))

out=tell(etude.morris,y= outputMorris$y)
print(etude.morris)

resMorris=data.frame(t(out$ee))
don_Morris=data.frame(parameter=parameters,mu=apply(X=resMorris,MARGIN = 1,mean),mu_star=apply(X=abs(resMorris),MARGIN = 1,mean),sd=apply(X=resMorris,MARGIN = 1,sd))


###----graphs
plot(etude.morris,main=paste('Morris indices'))
