#!/usr/bin/env python3

import json
import logging
import logging.config
from os import getenv
from os.path import basename

import flask
import requests
from flask import request
from flask_cors import CORS
from flask_restful import Api, Resource


def get_logger(name) -> logging.Logger:
    def get_stream_handler() -> logging.StreamHandler:

        handler = logging.StreamHandler()

        # noinspection SpellCheckingInspection
        log_format = "%(asctime)s %(message)s"
        formatter = logging.Formatter(log_format)

        handler.setFormatter(formatter)
        handler.setLevel(logging.DEBUG)

        return handler

    result = logging.getLogger(name)
    result.setLevel(logging.DEBUG)

    result.addHandler(get_stream_handler())

    return result


def get_1c_config() -> dict:

    result = {
        "1c_url": getenv("RFQ_1C_URL"),
        "1c_username": getenv("RFQ_1C_USERNAME"),
        "1c_password": getenv("RFQ_1C_PASSWORD"),
    }

    if result.get("1c_url") is None:
        logger.error("Unable to get URL of infobase HTTP service!")
        exit(1)


def get_1c_url(path: str) -> str:

    result = config["1c_url"]
    result = result if result.endswith("/") else f"{result}/"
    result = f"{result}{path}/"

    return result


def get_1c_auth() -> tuple | None:

    result = None

    if config["1c_username"] is not None:
        result = (config["1c_username"], config["1c_password"])

    return result


def get_api_response(data: dict) -> flask.Response:
    return flask.Response(response=json.dumps(data), mimetype="application/json")


def get_api_response_with_check(response: requests.Response) -> flask.Response:

    logger.debug(
        "Response status code: %s, text:\n%s", response.status_code, response.text
    )

    if response.status_code == 200:
        data = response.json()
    else:
        text = f"Inappropriate HTTP status code received ({response.status_code})."
        data = get_error_data_for_api_response(
            error_code=201,
            error_text=text,
        )

    return get_api_response(data)


def send_get_request_to_1c(path: str) -> requests.Response:
    url = get_1c_url(path)
    auth = get_1c_auth()

    logger.debug("Sending a GET request to %s", url)

    response = requests.get(url, auth=auth)

    return get_api_response_with_check(response)


def send_post_request_to_1c(path: str, data: dict) -> requests.Response:
    url = get_1c_url(path)
    auth = get_1c_auth()

    logger.debug("Send a POST a request to %s, body:\n%s", url, data)

    response = requests.post(url, json=data, auth=auth)

    return get_api_response_with_check(response)


def get_error_data_for_api_response(error_code: int, error_text: str) -> dict:
    return {"ErrorCode": error_code, "ErrorText": error_text}


class Home(Resource):
    @staticmethod
    def get():
        data = get_error_data_for_api_response(
            error_code=200, error_text="No endpoint specified."
        )
        return get_api_response(data)


class Ping(Resource):
    @staticmethod
    def get():
        return send_get_request_to_1c("Ping")


class Data(Resource):
    @staticmethod
    def get_path(rfq_key: str):
        return f"Data/{rfq_key}"

    @staticmethod
    def get(rfq_key: str):
        path = Data.get_path(rfq_key)

        return send_get_request_to_1c(path)

    @staticmethod
    def post(rfq_key: str):
        path = Data.get_path(rfq_key)
        body = request.get_json()

        return send_post_request_to_1c(path, body)


logger = get_logger(basename(__file__))
config = get_1c_config()

app = flask.Flask(__name__)

CORS(app)

api = Api(app)

api.add_resource(Home, "/")
api.add_resource(Ping, "/Ping/")
api.add_resource(Data, "/Data/<rfq_key>/")

if __name__ == "__main__":
    app.run()
