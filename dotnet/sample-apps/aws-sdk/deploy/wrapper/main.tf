module "hello-lambda-function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = ">= 2.24.0"

  architectures = compact([var.architecture])
  function_name = var.name
  handler       = "AwsSdkSample::AwsSdkSample.Function::TracingFunctionHandler"
  runtime       = "dotnet6"

  create_package         = false
  local_existing_package = "${path.module}/../../wrapper/SampleApps/build/function.zip"

  memory_size = 384
  timeout     = 20

  layers = compact([
    var.collector_layer_arn
  ])

  environment_variables = {
    OTEL_TRACES_SAMPLER         = "always_on"
  }

  tracing_mode = var.tracing_mode

  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets"
      ]
      resources = [
        "*"
      ]
    }
  }
}

module "api-gateway" {
  source = "../../../../../utils/terraform/api-gateway-proxy"

  name                = var.name
  function_name       = module.hello-lambda-function.lambda_function_name
  function_invoke_arn = module.hello-lambda-function.lambda_function_invoke_arn
  enable_xray_tracing = var.tracing_mode == "Active"
}
