#!/usr/bin/env python3

import json
import os
import shutil
import tempfile

import sh

# Quik and dirty Solidity doc generator
def gen_md(contract_name):
    with open("{}.docdev".format(contract_name)) as fp:
        docdev_data = fp.read()

    with open("{}.docuser".format(contract_name)) as fp:
        docuser_data = fp.read()

    docdev = json.loads(docdev_data)
    docuser = json.loads(docuser_data)

    for method_name in docdev['methods']:
        docdev['methods'][method_name].update(docuser['methods'][method_name])

    docmd = """# {}

""".format(docdev.get("title", ""))

    for method_name, method_info in sorted(docdev['methods'].items(), key=lambda x: x[0]):
        docmd += """### `{}`

""".format(method_name)

        if "notice" in method_info:

            docmd += """{}

""".format(method_info["notice"])

        if "details" in method_info:
            docmd += """{}

""".format(method_info["details"])

        if "params" in method_info:
            docmd += """**Parameters:**

"""
            for param_name, param_description in method_info["params"].items():
                docmd += """  - `{}`: {}
""".format(param_name, param_description)
            docmd += """
"""

        if "return" in method_info:
            docmd += """**Returns:**

{}

""".format(method_info["return"])

    return docmd


def gen_web3_deploy():
    with open("../abi/Legolas.abi") as fp:
        abi_data = fp.read()
    with open("../bin/Legolas.bin") as fp:
        bin_data = fp.read()

    deployjs = """var legolasContract = web3.eth.contract({});
var lgo = legolasContract.new({{
    from: web3.eth.accounts[0],
    data: '0x{}',
    gas: '4700000'
}}, function (e, contract) {{
    console.log(e, contract);
    if (typeof contract.address !== 'undefined') {{
        console.log('Contract mined! address: ' + contract.address + ' transactionHash: ' + contract.transactionHash);
    }}
}});""".format(abi_data, bin_data)

    with open("../deploy.js", "w+") as fp:
        fp.write(deployjs)


for dirname in ["doc", "bin", "abi"]:
    if os.path.isdir(dirname):
        shutil.rmtree(dirname)
    os.mkdir(dirname)

temp_dir = tempfile.mkdtemp()

os.chdir("sol/")

sh.solc("Legolas.sol", abi=True, overwrite=True, output_dir=temp_dir)
os.rename("{}/Legolas.abi".format(temp_dir), "../abi/Legolas.abi")

sh.solc("Legolas.sol", bin=True, overwrite=True, output_dir=temp_dir)
os.rename("{}/Legolas.bin".format(temp_dir), "../bin/Legolas.bin")

sh.solc("Legolas.sol", userdoc=True, devdoc=True, overwrite=True, output_dir=temp_dir)
os.rename("{}/Legolas.docuser".format(temp_dir), "../doc/Legolas.docuser")
os.rename("{}/Legolas.docdev".format(temp_dir), "../doc/Legolas.docdev")

with open("../doc/README.md", "w+") as fp:
    print(gen_md("../doc/Legolas"))
    fp.write(gen_md("../doc/Legolas"))

gen_web3_deploy()

shutil.rmtree(temp_dir)
