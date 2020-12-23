import json
import threading
import paho.mqtt.client as mqtt
import config

class Client():
    """MQTT client as context manager"""
    def __init__(self, enable=True):
        self.enable = enable
        self.client = mqtt.Client()
        self.client.enable_logger()
        self.client.tls_set(ca_certs=config.mqtt_certs)
        self.client.username_pw_set(config.mqtt_user, config.mqtt_pass)
        self.mid = None
        self.cv = threading.Condition()
        self.client.on_publish = self.__handle_publish

    def __enter__(self):
        if self.enable:
            self.client.connect(config.mqtt_broker, port=config.mqtt_port)
            self.client.loop_start()
        return self

    def __exit__(self, type, value, traceback):
        if self.enable:
            self.client.loop_stop()
            self.client.disconnect()
        print("exit")

    def __handle_publish(self, client, userdata, mid):
        with self.cv:
            self.mid = mid
            self.cv.notify()

    def __publish(self, msg, level, timeout=1):
        """
        Publish MQTT message with timeout
        """
        msg = {
            "level": level,
            "component": "transcoding/" + config.mqtt_host,
            "msg": msg,
        }
        payload = json.dumps(msg)
        res = self.client.publish("/voc/alert", payload)
        if res.rc != mqtt.MQTT_ERR_SUCCESS:
            print("MQTT publish failed with", res.rc)
            return
        sent_mid = lambda: self.mid == res.mid
        with self.cv:
            if not self.cv.wait_for(sent_mid, timeout):
                print("MQTT publish timeout")
                return
            print("success")

    def info(self, msg):
        if self.enable:
            self.__publish(msg, level="info")
