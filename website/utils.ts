export function signatureToVRS(signature: string): ({ v: number, r: string, s: string }) {
    const r = signature.slice(0, 66);
    const s = "0x" + signature.slice(66, 130);
    const v = parseInt(signature.slice(130, 132), 16);
    return { v, r, s };
}