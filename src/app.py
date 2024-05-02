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
import oss2
from oss2.credentials import EnvironmentVariableCredentialsProvider
import uuid

# When testing locally, make sure to set the environment variables ALIBABA_CLOUD_ACCESS_KEY_ID, ALIBABA_CLOUD_ACCESS_KEY_SECRET, BUCKET_ENDPOINT, and BUCKET_ID.
auth = oss2.ProviderAuth(EnvironmentVariableCredentialsProvider())
bucket = oss2.Bucket(
    auth, os.environ.get("BUCKET_ENDPOINT"), os.environ.get("BUCKET_ID")
)


def is_local_environment():
    return "FC_FUNCTION_NAME" not in os.environ

def set_oss_config():
    os.environ["OSS_ACCESS_KEY_ID"] = os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_ID")
    os.environ["OSS_ACCESS_KEY_SECRET"] = os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_SECRET")
    os.environ["OSS_SESSION_TOKEN"] = os.environ.get("ALIBABA_CLOUD_SECURITY_TOKEN")

def get_api_key():
    if is_local_environment():
        return os.environ.get("DASHSCOPE_API_KEY")
    else:
        function_compute_config = CredClientConfig(
            type="sts",
            access_key_id=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_ID"),
            access_key_secret=os.environ.get("ALIBABA_CLOUD_ACCESS_KEY_SECRET"),
            security_token=os.environ.get("ALIBABA_CLOUD_SECURITY_TOKEN"),
        )
        cred_client = CredClient(function_compute_config)
        config = open_api_models.Config(
            credential=cred_client, region_id=os.environ.get("REGION")
        )
        oos_client = client.Client(config=config)
        get_secret_request = oos_models.GetSecretParameterRequest(
            name="serverless-image-generation/dashscope-api-key", with_decryption=True
        )
        api_key = oos_client.get_secret_parameter(
            get_secret_request
        ).body.parameter.value
        return api_key


def upload_sketch(sketch):
    oss_key = f"tmp/{str(uuid.uuid4())}.png"
    with open(sketch["composite"], "rb") as oss_object:
        bucket.put_object(oss_key, oss_object)
        url = bucket.sign_url("GET", oss_key, 30, slash_safe=True)
        return url


def text_to_image_generator(prompt, image_count):
    ImageSynthesis.task = "text2image"
    task = ImageSynthesis.async_call(
        model=ImageSynthesis.Models.wanx_v1,
        prompt=prompt,
        n=image_count,
        negative_prompt="low resolution, ugly, blurry, low quality, out of focus",
    )
    response = ImageSynthesis.wait(task)
    images = [image.url for image in response.output.results]
    return gr.Gallery(images)


def sketch_to_image_generator(sketch, style, prompt, image_count):
    sketch_image_url = upload_sketch(sketch)
    ImageSynthesis.task = "image2image"
    task = ImageSynthesis.async_call(
        model="wanx-sketch-to-image-lite",
        sketch_image_url=sketch_image_url,
        prompt=prompt,
        n=image_count,
        negative_prompt="low resolution, ugly, blurry, low quality, out of focus",
        style=style,
    )
    response = ImageSynthesis.wait(task)
    images = [image.url for image in response.output.results]
    return gr.Gallery(images)


text_to_image_interface = gr.Interface(
    fn=text_to_image_generator,
    inputs=[
        gr.Textbox(
            label="Description", info="The prompt that will generate the image."
        ),
        gr.Slider(
            step=1,
            minimum=1,
            maximum=4,
            label="Image count",
            info="How many images would you like to generate?",
        ),
    ],
    outputs=["gallery"],
    allow_flagging="never",
)

with gr.Blocks() as sketch_to_image_interface:
    with gr.Row():
        with gr.Column(scale=3):
            sketch_pad = gr.Sketchpad(
                type="filepath", brush=gr.Brush(default_size=2, default_color="black")
            )
        with gr.Column(scale=1):
            style = gr.Dropdown(
                label="Art style",
                value="<3d cartoon>",
                choices=[
                    ("3D", "<3d cartoon>"),
                    ("Cartoon", "<anime>"),
                    ("Oil painting", "<oil painting>"),
                    ("Watercolor", "<watercolor>"),
                    ("Minimalist", "<flat illustration>"),
                ],
            )
            image_count = gr.Slider(
                step=1,
                minimum=1,
                maximum=4,
                label="Image count",
                info="How many images would you like to generate?",
            )
            prompt = gr.Textbox(
                label="Description", info="A prompt that describes your sketch."
            )
            clear_btn = gr.ClearButton()
            btn = gr.Button(value="Submit", variant="primary")
        with gr.Column(scale=3):
            gallery = gr.Gallery()
    btn.click(
        fn=sketch_to_image_generator,
        inputs=[sketch_pad, style, prompt, image_count],
        outputs=[gallery],
    )
    clear_btn.add(
        [image_count, prompt, gallery, style]
    )  # Sketchpad is not added as button functionality currently does not consistently clear sketchpad inputs.
    clear_btn.click()

with gr.Blocks(
    theme=gr.themes.Soft(),
    css="footer {visibility: hidden} output_image {height: 40rem !important; width: 100% !important;}",
) as demo:
    gr.Markdown(
        """
        # Serverless Image Generation with Function Compute and Tongyi Wanxiang
                
        This is a serverless application that can be used to generate images from text prompts as well as pictures like sketches.\n
        It runs completely on Alibaba Cloud's [Function Compute](https://www.alibabacloud.com/product/function-compute), and uses Alibaba Cloud's own generative text-to-image and image-to-image model, [Tongyi Wanxiang](https://tongyi.aliyun.com/wanxiang/).\n
        Want to know more? Take a look at the [GitHub project](https://github.com/dmolenaars/serverless-image-generation).
    """
    )
    gr.TabbedInterface(
        [text_to_image_interface, sketch_to_image_interface],
        ["Text to image", "Sketch to image"],
    )
if __name__ == "__main__":
    dashscope.api_key = get_api_key()
    set_oss_config()
    demo.launch(share=False, server_name="0.0.0.0")
