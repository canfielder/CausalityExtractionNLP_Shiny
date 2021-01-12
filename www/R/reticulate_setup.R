#' The following script sets up the Reticulate system settings.
# 

# --- VIRTUALENV Setup ------------------------------------------------------- #

reticulate_setup <- function() {
  
  virtualenv_dir <- Sys.getenv('VIRTUALENV_NAME')
  python_path <- Sys.getenv('PYTHON_PATH')
  PYTHON_DEPENDENCIES <- c('numpy',  'sklearn', 'joblib', 
                           'tensorflow', 'tika')
  
  # Create virtual env and install dependencies
  reticulate::virtualenv_create(envname = virtualenv_dir, python = python_path)
  reticulate::virtualenv_install(virtualenv_dir,
                                 packages = PYTHON_DEPENDENCIES,
                                 ignore_installed=TRUE)

  # Assign Virtual Environment
  reticulate::use_virtualenv(virtualenv_dir, required = TRUE)
  
}


# --- VIRTUALENV Setup ------------------------------------------------------- #