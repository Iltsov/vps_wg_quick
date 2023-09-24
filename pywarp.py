import random

import httpx

base_url = "https://api.cloudflareclient.com"
base_headers = {
    "CF-Client-Version": "a-6.22-2970",
    "Host": "api.cloudflareclient.com",
    "Connection": "Keep-Alive",
    "Accept-Encoding": "gzip",
    "User-Agent": "okhttp/3.12.1",
}

keys = (
    "pbI956P4-59NBH34e-uI5VO714",
    "0bd514cB-741QE2iF-4h1QKu32",
    "0S53DbW1-q210trW3-b71O6H4k",
    "wQ1Rx784-287Of9Lc-37Qn1Vm0",
    "IDk196C5-6X9xE81i-0b98h6cG",
    "0IJx23X8-b90Z3Sd1-7y4G9qH6",
    "0ve61g8h-q57w41RB-sG4k716M",
    "5C46lK1F-9f5SwP17-38HF9Vd4",
    "4k25Vm7j-Qwo1245e-9X8R1e6Q",
    "A0I6Gf42-25QW4Tz8-34X5mur6",
    "jyE578C4-Wny1074N-6HfF3S80",
    "q132HD8y-1zmP3L60-n9134Sug",
)


def get_reg(client, json={}):
    url = "/v0a2970/reg"
    headers = {"Content-Type": "application/json; charset=UTF-8"}
    r = client.post(url, headers=headers, json=json)
    reg_id = r.json()["id"]
    token = r.json()["token"]
    license = r.json()["account"]["license"]
    return reg_id, token, license


def add_key(client, reg_id, token, license=random.choice(keys)):
    url = f"/v0a2970/reg/{reg_id}/account"
    headers = {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": f"Bearer {token}",
    }
    json = {"license": f"{license}"}
    r = client.put(url, headers=headers, json=json)


def get_info(client, reg_id, token):
    url = f"/v0a2970/reg/{reg_id}/account"
    headers = {"Authorization": f"Bearer {token}"}
    r = client.get(url, headers=headers)
    account_type = r.json()["account_type"]
    referral_count = r.json()["referral_count"]
    license = r.json()["license"]
    return account_type, referral_count, license


def del_reg(client, reg_id, token):
    url = f"/v0a2970/reg/{reg_id}"
    headers = {"Authorization": f"Bearer {token}"}
    r = client.delete(url, headers=headers)


def main():
    with httpx.Client(base_url=base_url, headers=base_headers, timeout=15.0) as client:
        reg = get_reg(client)
        json = {"referrer": f"{reg[0]}"}
        get_reg(client, json)
        add_key(client, reg[0], reg[1])
        add_key(client, reg[0], reg[1], reg[2])
        info = get_info(client, reg[0], reg[1])
        del_reg(client, reg[0], reg[1])
        print(f"Тип аккаунта: {info[0]}")
        print(f"Данных выделено: {info[1]} Гбайт")
        print(f"Лицензия: {info[2]}")
        with open('./key', 'w') as f:
            f.write(info[2])


main()
