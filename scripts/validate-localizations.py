#!/usr/bin/env python3
"""Check VERA language coverage, web language parity and printf arguments."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Same choices/order as vonage-video-react-app's LanguageSelector (77c9b91).
LANGUAGES = ['en', 'en-US', 'de', 'it', 'es', 'es-MX', 'ja']


def signature(value):
    tokens = re.findall(r'%(?:(\d+)\$)?(@|lld|ld|d|f)', value)
    return sorted((int(position) if position else index + 1, kind)
                  for index, (position, kind) in enumerate(tokens))


def validate():
    count = 0
    needs_review = 0
    for catalog in ROOT.joinpath('VERA').rglob('*.xcstrings'):
        data = json.loads(catalog.read_text())
        assert data['sourceLanguage'] == 'en', catalog
        for key, entry in data['strings'].items():
            localizations = entry.get('localizations', {})
            assert set(localizations) == set(LANGUAGES), (catalog, key, 'language coverage')
            source = localizations['en']['stringUnit']['value']
            for language in LANGUAGES:
                unit = localizations[language]['stringUnit']
                value = unit['value']
                assert not source or value, (catalog, key, language, 'empty translation')
                assert '{{' not in value, (catalog, key, language, 'web placeholder')
                assert signature(value) == signature(source), (catalog, key, language, 'printf arguments')
                needs_review += unit['state'] == 'needs_review'
            assert localizations['en-US']['stringUnit']['value'] == source, (catalog, key, 'English alias')
            count += 1
    assert count > 0, 'No catalogs found'
    config = ROOT.joinpath('VERA/Tuist/ProjectDescriptionHelpers/BuildSettingsConfig.swift').read_text()
    configured = re.search(r'supportedLanguages: \[String\] = \[(.*?)\]', config).group(1)
    assert re.findall(r'"(.*?)"', configured) == LANGUAGES, 'Tuist language declaration differs'
    enum_path = ROOT.joinpath('VERA/VERACommonUI/VERACommonUI/Localization/AppLanguageStore.swift')
    if enum_path.exists():
        enum_source = enum_path.read_text()
        assert re.findall(r'case \w+ = "(.*?)"', enum_source) == LANGUAGES, 'Language selector differs'
    print(f'Validated {count} catalog entries across {len(LANGUAGES)} languages; '
          f'{needs_review} native translations marked for linguistic review.')


if __name__ == '__main__':
    validate()
