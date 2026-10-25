export * from "./GlobalTypes";

export interface SchemaJsonLdType {
    "@context": string;
    "@type": string;
    [key: string]: unknown;
}
