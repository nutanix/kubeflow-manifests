## Running Website locally

1. This website is being generated with [Hugo](https://gohugo.io/), a popular open-source static site generator. You will need to install the `extended` version of Hugo to be able to generate a website locally.

    You can install Hugo using `brew`:
    ```bash
    brew install hugo
    ```

    Alternatively, you can also use `snap`:
    ```bash
    snap install hugo --channel=extended
    ```

    Check the [official documentation](https://gohugo.io/getting-started/installing/) on other installation options. See more details on how to deploy [GitHub pages static website using Hugo](https://gohugo.io/hosting-and-deployment/hosting-on-github/).

2. We use [Docsy](https://github.com/google/docsy) theme, which has its prerequisites.

    ```bash
    npm install
    ```
    If you don't have `npm`, install it using:
    ```bash
    sudo apt-get install npm
    ```

3. To run the website locally:

    ```bash
    hugo server
    ```
