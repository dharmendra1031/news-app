'use client';
import Link from 'next/link';
import { ComponentProps } from 'react';
import { useDefaultLangCode, useLangCode } from '@/hooks/useLangCode';
import { withLang } from '@/lib/localizedUrl';

type LocalizedLinkProps = Omit<ComponentProps<typeof Link>, 'href'> & { href: string };

const LocalizedLink = ({ href, ...rest }: LocalizedLinkProps) => {
    const lang = useLangCode();
    const defaultLang = useDefaultLangCode();
    return <Link href={withLang(href, lang, defaultLang)} {...rest} />;
};

export default LocalizedLink;
