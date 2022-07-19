#!/usr/bin/env python3

import json
import logging
import logging.config
import os

import flask
import requests
from flask import request
from flask_cors import CORS
from flask_restful import Api, Resource


def get_logger(name) -> logging.Logger:
    def get_stream_handler() -> logging.StreamHandler:
        handler = logging.StreamHandler()

        log_format = f"%(asctime)s %(message)s"
        formatter = logging.Formatter(log_format)

        handler.setFormatter(formatter)
        handler.setLevel(logging.DEBUG)

        return handler

    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    logger.addHandler(get_stream_handler())

    return logger


def get_config() -> dict:
    return {
        "1c_http_service_url": os.getenv("RFQ_1C_HS_URL"),
        "1c_http_service_username": os.getenv("RFQ_1C_HS_USERNAME"),
        "1c_http_service_password": os.getenv("RFQ_1C_HS_PASSWORD"),
    }


def get_infobase_http_service_url(path: str) -> str:
    result = CONFIG["1c_http_service_url"]
    result = result if result.endswith("/") else f"{result}/"
    result = "{}{}/".format(result, path)

    return result


def get_infobase_http_service_auth() -> tuple | None:
    result = None

    if CONFIG["1c_http_service_username"]:
        result = (
            CONFIG["1c_http_service_username"],
            CONFIG["1c_http_service_password"],
        )

    return result


def get_api_response(data: dict) -> flask.Response:
    return flask.Response(response=json.dumps(data), mimetype="application/json")


def get_api_response_using_status_code(
    response: requests.models.Response,
) -> flask.Response:
    LOGGER.debug(
        "Response status code: {}, text:\n{}".format(
            response.status_code, response.text
        )
    )

    if response.status_code == 200:
        data = response.json()
    else:
        data = get_data_for_api_response_with_error_description(
            error_code=201,
            error_text="Inappropriate HTTP status code received ({}).".format(
                response.status_code
            ),
        )

    return get_api_response(data)


def send_get_request_to_infobase_http_service(path: str) -> requests.Response:
    auth = get_infobase_http_service_auth()
    url = get_infobase_http_service_url(path)

    LOGGER.debug("Sending a GET request to {}".format(url))

    response = requests.get(url, auth=auth)

    return get_api_response_using_status_code(response)


def send_post_request_to_infobase_http_service(
    path: str, data: dict
) -> requests.Response:
    url = get_infobase_http_service_url(path)
    auth = get_infobase_http_service_auth()

    LOGGER.debug("Send a POST a request to {}, body:\n{}".format(url, data))

    response = requests.post(url, json=data, auth=auth)

    return get_api_response_using_status_code(response)


def get_data_for_api_response_with_error_description(
    error_code: int, error_text: str
) -> dict:
    return {"ErrorCode": error_code, "ErrorText": error_text}


class Hello(Resource):
    @staticmethod
    def get():
        data = get_data_for_api_response_with_error_description(
            error_code=200, error_text="No endpoint specified."
        )
        return get_api_response(data)


class Ping(Resource):
    @staticmethod
    def get():
        return send_get_request_to_infobase_http_service("Ping")


class RFQ(Resource):
    @staticmethod
    def get_path(rfq_key: str):
        return f"RequestForQuotation/{rfq_key}"

    @staticmethod
    def get(rfq_key: str):
        path = RFQ.get_path(rfq_key)

        return send_get_request_to_infobase_http_service(path)

    @staticmethod
    def post(rfq_key: str):
        path = RFQ.get_path(rfq_key)
        body = request.get_json()

        return send_post_request_to_infobase_http_service(path, body)


CURRENT_DIRECTORY = os.path.abspath(os.path.dirname(__file__))

CONFIG = get_config()
LOGGER = get_logger(os.path.basename(__file__))

app = flask.Flask(__name__)

CORS(app)

api = Api(app)

api.add_resource(Hello, "/")
api.add_resource(Ping, "/Ping/")
api.add_resource(RFQ, "/RequestForQuotation/<rfq_key>/")

if __name__ == "__main__":
    app.run()
