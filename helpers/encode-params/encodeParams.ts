import { IEncodeParamsInputs } from "./interfaces";
const {toHex} = require('tronWeb')
const {utils} = require('ethers')

const AbiCoder = utils.AbiCoder;
const ADDRESS_PREFIX_REGEX = /^(41)/;
const ADDRESS_PREFIX = "41";


// https://developers.tron.network/docs/parameter-encoding-and-decoding
export function encodeParams(inputs: IEncodeParamsInputs){
    let typesValues = inputs
    let parameters = ''

    if (typesValues.length == 0)
        return parameters
    const abiCoder = new AbiCoder();
    let types = [];
    const values = [];

    for (let i = 0; i < typesValues.length; i++) {
        let {type, value} = typesValues[i];
        if (type == 'address')
            value = (value as string).replace(ADDRESS_PREFIX_REGEX, '0x');
        else if (type == 'address[]')
            value = (value as string[]).map(v => toHex(v).replace(ADDRESS_PREFIX_REGEX, '0x'));
        types.push(type);
        values.push(value);
    }

    console.log(types, values)
    try {
        parameters = abiCoder.encode(types, values).replace(/^(0x)/, '');
    } catch (ex) {
        console.log(ex);
    }
    return parameters
}