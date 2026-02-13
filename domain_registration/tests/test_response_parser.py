"""Tests for domain registration response parser and analyzer."""

import unittest
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

from domain_registration.response_parser import (
    DomainInfo,
    RegistrationResponse,
    analyze_response,
    parse_and_analyze,
    parse_response,
)

SAMPLE_XML = """\
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<domainRegistrationResponse>
  <status>success</status>
  <domain>
    <name>example.com</name>
    <registrant>John Doe</registrant>
    <registrar>Example Registrar Inc.</registrar>
    <registrationDate>2026-01-15T10:30:00Z</registrationDate>
    <expirationDate>2027-01-15T10:30:00Z</expirationDate>
    <nameservers>
      <nameserver>ns1.example.com</nameserver>
      <nameserver>ns2.example.com</nameserver>
    </nameservers>
  </domain>
  <transactionId>TXN-2026-00001</transactionId>
</domainRegistrationResponse>
"""

MINIMAL_XML = """\
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<domainRegistrationResponse>
  <status>pending</status>
  <domain>
    <name>minimal.com</name>
    <registrant>Jane Doe</registrant>
    <registrar>Min Registrar</registrar>
    <registrationDate>2026-06-01T00:00:00Z</registrationDate>
    <expirationDate>2027-06-01T00:00:00Z</expirationDate>
  </domain>
  <transactionId>TXN-MIN-001</transactionId>
</domainRegistrationResponse>
"""


class TestParseResponse(unittest.TestCase):
    """Tests for parse_response function."""

    def test_parse_full_response(self):
        result = parse_response(SAMPLE_XML)

        self.assertIsInstance(result, RegistrationResponse)
        self.assertEqual(result.status, "success")
        self.assertEqual(result.domain.name, "example.com")
        self.assertEqual(result.domain.registrant, "John Doe")
        self.assertEqual(result.domain.registrar, "Example Registrar Inc.")
        self.assertEqual(result.transaction_id, "TXN-2026-00001")
        self.assertEqual(len(result.domain.nameservers), 2)
        self.assertIn("ns1.example.com", result.domain.nameservers)
        self.assertIn("ns2.example.com", result.domain.nameservers)

    def test_parse_dates(self):
        result = parse_response(SAMPLE_XML)

        expected_reg = datetime(2026, 1, 15, 10, 30, 0, tzinfo=timezone.utc)
        expected_exp = datetime(2027, 1, 15, 10, 30, 0, tzinfo=timezone.utc)
        self.assertEqual(result.domain.registration_date, expected_reg)
        self.assertEqual(result.domain.expiration_date, expected_exp)

    def test_parse_minimal_response(self):
        result = parse_response(MINIMAL_XML)

        self.assertEqual(result.status, "pending")
        self.assertEqual(result.domain.name, "minimal.com")
        self.assertEqual(result.domain.nameservers, [])

    def test_missing_status_raises(self):
        xml = "<domainRegistrationResponse><domain><name>a</name><registrant>b</registrant><registrar>c</registrar><registrationDate>2026-01-01T00:00:00Z</registrationDate><expirationDate>2027-01-01T00:00:00Z</expirationDate></domain><transactionId>T</transactionId></domainRegistrationResponse>"
        with self.assertRaises(ValueError):
            parse_response(xml)

    def test_missing_domain_raises(self):
        xml = "<domainRegistrationResponse><status>ok</status><transactionId>T</transactionId></domainRegistrationResponse>"
        with self.assertRaises(ValueError):
            parse_response(xml)

    def test_missing_transaction_id_raises(self):
        xml = "<domainRegistrationResponse><status>ok</status><domain><name>a</name><registrant>b</registrant><registrar>c</registrar><registrationDate>2026-01-01T00:00:00Z</registrationDate><expirationDate>2027-01-01T00:00:00Z</expirationDate></domain></domainRegistrationResponse>"
        with self.assertRaises(ValueError):
            parse_response(xml)

    def test_malformed_xml_raises(self):
        with self.assertRaises(ET.ParseError):
            parse_response("<not valid xml")


class TestAnalyzeResponse(unittest.TestCase):
    """Tests for analyze_response function."""

    def test_analyze_full_response(self):
        response = parse_response(SAMPLE_XML)
        analysis = analyze_response(response)

        self.assertEqual(analysis["domain_name"], "example.com")
        self.assertEqual(analysis["status"], "success")
        self.assertEqual(analysis["registrant"], "John Doe")
        self.assertEqual(analysis["registrar"], "Example Registrar Inc.")
        self.assertEqual(analysis["nameserver_count"], 2)
        self.assertEqual(analysis["validity_days"], 365)
        self.assertEqual(analysis["transaction_id"], "TXN-2026-00001")

    def test_analyze_minimal_response(self):
        response = parse_response(MINIMAL_XML)
        analysis = analyze_response(response)

        self.assertEqual(analysis["nameserver_count"], 0)
        self.assertEqual(analysis["nameservers"], [])
        self.assertEqual(analysis["validity_days"], 365)


class TestParseAndAnalyze(unittest.TestCase):
    """Tests for parse_and_analyze convenience function."""

    def test_full_pipeline(self):
        result = parse_and_analyze(SAMPLE_XML)

        self.assertIsInstance(result, dict)
        self.assertEqual(result["domain_name"], "example.com")
        self.assertEqual(result["status"], "success")
        self.assertEqual(result["nameserver_count"], 2)
        self.assertEqual(result["validity_days"], 365)


if __name__ == "__main__":
    unittest.main()
