# Activate the datavizs24 project when opening RStudio Server
setHook("rstudio.sessionInit", function(newSession) {
  if (newSession && is.null(rstudioapi::getActiveProject()))
    rstudioapi::openProject("datavizs24")
}, action = "append")
