# keep the response cache of the tests out of the user's cache folder
withr::local_options(synthcheck.cache_dir = tempfile("synthcheck-cache-"), .local_envir = teardown_env())
