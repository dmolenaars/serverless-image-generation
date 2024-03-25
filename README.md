# Serverless Image Generation with Function Compute and Tongyi Wanxiang

![Example prompt](example.png)
This is a serverless application that can be used to generate images from text prompts. It runs completely on Alibaba Cloud's [Function Compute](https://www.alibabacloud.com/product/function-compute).

This project uses DashScope, Alibaba Cloud's Model as a Service (MaaS) platform, in combination with Alibaba Cloud's own generative text-to-image model, [Tongyi Wanxiang](https://tongyi.aliyun.com/wanxiang/).

Looking for a live demo? Click [here](https://genaiwithali.cloud/).

## Application setup
### Installing dependencies
You can use the provided `devcontainer.json` configuration to launch a devcontainer with the preinstalled dependencies in your own IDE or in GitHub Codespaces.

You can also directly install the dependencies on your host machine with the following command:

 `pip install -r ./src/requirements.txt`


### Setting up environment variables
A DashScope API key is needed. Currently, DashScope is only available to users with an Alibaba Cloud domestic account, but an international version is being worked on. You can apply for an API key [here](https://dashscope.console.aliyun.com/apiKey).

#### Local development
For local development, set an environment variable called `DASHSCOPE_API_KEY` as follows:

`export DASHSCOPE_API_KEY=<YOUR API KEY>`

#### Deploying to your own Alibaba Cloud account
If you want to use the application in your own Alibaba Cloud account, you will need to deploy the application using the provided Terraform stack, which will automatically create a secret parameter called `serverless-image-generation/dashscope-api-key`. Replace the placeholder variable in this parameter with your API key using the Alibaba Cloud console or the CLI.

### Launching the application
You can launch the application with the following command: 

`python ./src/app.py`

You will be able to view the application in your browser on `127.0.0.1:7860`.

## Infrastructure
The infrastructure consists of a single [Function Compute](https://www.alibabacloud.com/en/product/function-compute) function and a [CloudOps Orchestration Service](https://www.alibabacloud.com/en/product/oos) Secret Parameter that can be used to store the DashScope API key. The Function Compute role has basic permissions to access the parameter.

## Deployment
The [`alicloud`](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs) Terraform provider is used to define and deploy the infrastructure.

Deploy the infrastructure as follows:

`terraform init && terraform apply`

*Note: a custom domain name needs to be associated with the Function Compute function before you can access it through the web. Replace the placeholder `domain_name` property for the `alicloud_fc_custom_domain` resource in `modules/image_generator/main.tf` with your a domain name that you control.*