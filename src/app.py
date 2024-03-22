import dashscope
from dashscope import Generation, ImageSynthesis
import gradio as gr
import os
from alibabacloud_credentials.client import (
    Client as CredClient,
    Config as CredClientConfig,
)
from alibabacloud_oos20190601 import client, models as oos_models
from alibabacloud_tea_openapi import models as open_api_models

def is_function_compute_invocation():
    return os.environ.get("FC_FUNCTION_NAME") is not None,

def get_api_key():
    function_compute_config = CredClientConfig(
        type="sts",
        access_key_id=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_ID"),
        access_key_secret=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_SECRET"),
        security_token=os.environ.get("ALIBABA_CLOUD_SECURITY_TOKEN"),
    )
    cred_client = CredClient(function_compute_config) if is_function_compute_invocation() else CredClient()
    config = open_api_models.Config(
        credential=cred_client, region_id="eu-central-1"
    )
    oos_client = client.Client(config=config)
    get_secret_request = oos_models.GetSecretParameterRequest(
        name="serverless-image-generation/dashscope-api-key", with_decryption=True
    )
    api_key = oos_client.get_secret_parameter(get_secret_request).body.parameter.value
    return api_key


def image_generator(description):
    initial_prompt = f"""Generate a detailed fully English prompt that will be used for text to image generation. Base your prompt on this original description:```
        ```
            {description}
        ```
        Please return the prompt only, nothing else.
        """

    initial_prompt_response = Generation.call(
        model="qwen-plus",
        prompt=initial_prompt,
    )
    text2image_prompt = initial_prompt_response.output["text"]
    task = ImageSynthesis.async_call(
        model=ImageSynthesis.Models.wanx_v1,
        prompt=text2image_prompt,
        n=1,
        negative_prompt="low resolution, ugly, blurry, low quality, out of focus",
    )
    text2image_prompt_response = ImageSynthesis.wait(task)
    return gr.Image(type="pil", value=text2image_prompt_response.output.results[0].url)


demo = gr.Interface(
    fn=image_generator,
    inputs=["text"],
    outputs=["image"],
    theme=gr.themes.Soft(),
    css="footer {visibility: hidden}",
    allow_flagging="never",
    title="Serverless Image Generation with Function Compute",
)


if __name__ == "__main__":
    dashscope.api_key = get_api_key()
    demo.launch(share=False, server_name="0.0.0.0")