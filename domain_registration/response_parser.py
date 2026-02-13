"""Domain registration response parser and analyzer.

Parses and analyzes XML-based domain registration responses,
extracting domain details, status, and nameserver information.
"""

import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional


@dataclass
class DomainInfo:
    """Represents domain registration details."""
    name: str
    registrant: str
    registrar: str
    registration_date: datetime
    expiration_date: datetime
    nameservers: List[str] = field(default_factory=list)


@dataclass
class RegistrationResponse:
    """Represents a parsed domain registration response."""
    status: str
    domain: DomainInfo
    transaction_id: str


def parse_response(xml_content: str) -> RegistrationResponse:
    """Parse an XML domain registration response.

    Args:
        xml_content: XML string containing the domain registration response.

    Returns:
        RegistrationResponse with parsed domain details.

    Raises:
        ValueError: If the XML is missing required elements.
        ET.ParseError: If the XML is malformed.
    """
    root = ET.fromstring(xml_content)

    status_elem = root.find("status")
    if status_elem is None or status_elem.text is None:
        raise ValueError("Missing required element: status")

    domain_elem = root.find("domain")
    if domain_elem is None:
        raise ValueError("Missing required element: domain")

    name_elem = domain_elem.find("name")
    registrant_elem = domain_elem.find("registrant")
    registrar_elem = domain_elem.find("registrar")
    reg_date_elem = domain_elem.find("registrationDate")
    exp_date_elem = domain_elem.find("expirationDate")

    for elem, label in [
        (name_elem, "name"),
        (registrant_elem, "registrant"),
        (registrar_elem, "registrar"),
        (reg_date_elem, "registrationDate"),
        (exp_date_elem, "expirationDate"),
    ]:
        if elem is None or elem.text is None:
            raise ValueError(f"Missing required element: {label}")

    nameservers = []
    ns_elem = domain_elem.find("nameservers")
    if ns_elem is not None:
        for ns in ns_elem.findall("nameserver"):
            if ns.text:
                nameservers.append(ns.text)

    domain_info = DomainInfo(
        name=name_elem.text,
        registrant=registrant_elem.text,
        registrar=registrar_elem.text,
        registration_date=datetime.fromisoformat(
            reg_date_elem.text.replace("Z", "+00:00")
        ),
        expiration_date=datetime.fromisoformat(
            exp_date_elem.text.replace("Z", "+00:00")
        ),
        nameservers=nameservers,
    )

    txn_elem = root.find("transactionId")
    if txn_elem is None or txn_elem.text is None:
        raise ValueError("Missing required element: transactionId")

    return RegistrationResponse(
        status=status_elem.text,
        domain=domain_info,
        transaction_id=txn_elem.text,
    )


def analyze_response(response: RegistrationResponse) -> dict:
    """Analyze a parsed domain registration response.

    Returns a summary dict with key details and computed fields
    such as registration validity period in days.

    Args:
        response: A parsed RegistrationResponse object.

    Returns:
        Dictionary containing analysis results.
    """
    validity_days = (
        response.domain.expiration_date - response.domain.registration_date
    ).days

    return {
        "domain_name": response.domain.name,
        "status": response.status,
        "registrant": response.domain.registrant,
        "registrar": response.domain.registrar,
        "nameserver_count": len(response.domain.nameservers),
        "nameservers": response.domain.nameservers,
        "validity_days": validity_days,
        "transaction_id": response.transaction_id,
    }


def parse_and_analyze(xml_content: str) -> dict:
    """Parse XML content and return analysis results.

    Convenience function that combines parsing and analysis.

    Args:
        xml_content: XML string containing the domain registration response.

    Returns:
        Dictionary containing analysis results.
    """
    response = parse_response(xml_content)
    return analyze_response(response)
