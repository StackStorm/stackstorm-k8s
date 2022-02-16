import os
from typing import Any, Dict, List, Optional

import pytest

from .helm_template_generator import render_chart

# These fixtures provide some default values.
# Tests can override them with parametrized values.


@pytest.fixture
def kubernetes_version() -> str:
    """Return the default k8s version."""
    return "1.22.0"


@pytest.fixture
def release_name() -> str:
    """Return the default test release name."""
    return "st2-ha"


@pytest.fixture
def namespace() -> str:
    """Return the default test namespace."""
    return "st2"


@pytest.fixture
def values() -> Dict[str, Any]:
    """Return the default values."""
    return {}


@pytest.fixture
def show_only() -> List[str]:
    """Return the default list of resources to return from ``helm template``.

    If an empty list, then all resources will be made available.
    """
    return []


@pytest.fixture
def chart_dir() -> str:
    """Return the default chart_dir.

    Tests might want to override this with a temporary directory
    that copies a minimal set of the template files for a given test.
    """
    return os.path.dirname(os.path.dirname(__file__))


@pytest.fixture
def chart_resources(
    kubernetes_version: str,
    release_name: str,
    namespace: str,
    chart_dir: str,
    values: Dict[str, Any],
    show_only: List[str],
) -> List[Dict[str, Any]]:
    """Wrap the render_chart utility in a pytest.fixtrue."""
    return render_chart(
        name=release_name,
        values=values,
        show_only=show_only,
        chart_dir=chart_dir,
        kubernetes_version=kubernetes_version,
        namespace=namespace,
    )
