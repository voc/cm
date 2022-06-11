services {
  name = "http-upload"
  port = 8080
  checks = [
    {
      http = "http://localhost:8080/health"
      method = "GET"
      interval = "5s"
      timeout = "3s"
    }
  ]
}

