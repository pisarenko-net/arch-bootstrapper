import requests
import time
import os
import re
from requests.exceptions import RequestException
from datetime import datetime, timedelta


HA_PREPARE_TIMEOUT_MIN = 30
HA_RESTORE_TIMEOUT_MIN = 30
HA_START_RESTORE_TIMEOUT_MIN = 1
REQUEST_TIMEOUT_SEC = 30
RETRY_TIMEOUT_SEC = 5


def wait_for_ha_prepare(url, timeout=HA_PREPARE_TIMEOUT_MIN):
    end_time = datetime.now() + timedelta(minutes=timeout)

    while datetime.now() < end_time:
        try:
            response = requests.get(url, timeout=REQUEST_TIMEOUT_SEC, allow_redirects=False)
            print("  received code %s" % response.status_code)
            if response.status_code == 302:
                break
            if '<title>Home Assistant</title>' in response.text:
                print("==> Home Assistant is already configured, doing nothing!")
                return False
        except RequestException as e:
            print("==> Request to Home Assistant failed, retrying. Error:", str(e))

        print("==> Waiting for Home Assistant to initialize")
        time.sleep(RETRY_TIMEOUT_SEC)

    else:
        print("==> Home Assistant did not come up within timeout")
        return False

    return True


def upload_backup(url, file_path, field_name):
    file_data = open(file_path, 'rb')
    files = {field_name: ('home-assistant-backup.tar', file_data)}

    response = requests.post(url, files=files)
    print("  received code %s" % response.status_code)
    file_data.close()

    if response.status_code >= 400:
        print("==> Failed to upload Home Assistant backup")
        return ''

    return response.json()['data']['slug']


def wait_for_ha_restore(url, timeout=HA_RESTORE_TIMEOUT_MIN):
    end_time = datetime.now() + timedelta(minutes=timeout)

    while datetime.now() < end_time:
        try:
            response = requests.get(url, timeout=REQUEST_TIMEOUT_SEC, allow_redirects=False)
            print("  received code %s" % response.status_code)
            if response.status_code == 200 and '<title>Home Assistant</title>' in response.text:
                break
        except RequestException as e:
            print("==> Request to Home Assistant failed, retrying. Error:", str(e))

        print("==> Waiting for Home Assistant to prepare")
        time.sleep(RETRY_TIMEOUT_SEC)

    else:
        print("==> Home Assistant did not restore config within timeout")


def retry_restore_until_success(url, timeout=HA_START_RESTORE_TIMEOUT_MIN):
    end_time = datetime.now() + timedelta(minutes=timeout)

    while datetime.now() < end_time:
        try:
            response = requests.post(url, timeout=REQUEST_TIMEOUT_SEC)
            print("  received code %s" % response.status_code)
            if response.status_code == 200 or response.status_code == 502:
                break
        except RequestException as e:
            print("==> Request to Home Assistant failed, retrying. Error:", str(e))

        print("==> Request to restore backup failed with code %s" % response.status_code)
        time.sleep(RETRY_TIMEOUT_SEC)

    else:
        print("==> Home Assistant failed to initiate backup restore within allowed time-frame")


def main():
    url = "http://install.home-assistant.xama"

    if not wait_for_ha_prepare(url):
        return
    
    print("==> Home Assistant is Ready, going to upload backup.")

    upload_url = "http://install.home-assistant.xama/api/hassio/backups/new/upload"
    upload_slug = upload_backup(upload_url, os.path.join(os.getcwd(), 'home-assistant-backup.tar'), 'file')
    if not upload_slug:
        return
    print("==> Successfully uploaded backup and received code %s" % upload_slug)

    retry_restore_until_success("http://install.home-assistant.xama/api/hassio/backups/%s/restore/full" % upload_slug)

    print("==> Started full restore")

    wait_for_ha_restore(url)

    print("==> Complete. Giving Home Assistant 10 minutes before final reboot, just in case.")
    time.sleep(10 * 60)

if __name__ == "__main__":
    main()

