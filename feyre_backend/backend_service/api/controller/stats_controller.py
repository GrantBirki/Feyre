import datetime
from http import HTTPStatus
from flask import Blueprint, request
from backend_service.api.operation.stats_operation import StatsOperation
from common.redis_helper import RedisHelper

stats_api = Blueprint('stats', __name__)
redis_helper = RedisHelper()

@stats_api.route('/', methods=['GET'])
def stats():
    """
    Returns the stats dictionary

    Query Paramters:
        all: (true/false) Returns all stats instead of a subset
    ---
    """
    redis_helper.red.incr('c_stats', amount = 1)

    show_all = False
    args = request.args

    # Add the user id to the user set
    if "user" in args:
        user = args["user"]
        redis_helper.red.sadd("user_set", user)
        redis_helper.red.set("user_set:updated_time", datetime.now().timestamp())
    else:
        return "Missing user query parameter", HTTPStatus.BAD_REQUEST

    if "all" in args:
        show_all = bool(args["all"])
    try:
        result = StatsOperation(redis = redis_helper.red, show_all = show_all).execute()
        return result, HTTPStatus.OK
    except Exception as e:
        return str(e), HTTPStatus.INTERNAL_SERVER_ERROR
    