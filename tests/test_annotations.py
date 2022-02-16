from typing import Any, Dict, List

import pytest


@pytest.mark.parametrize(
    ("values", "show_only", "expected_annotations"),
    [
        (
            {"serviceAccount": {"serviceAccountAnnotations": {"foo": "bar"}}},
            ["templates/service-account.yaml"],
            {"foo": "bar"},
        ),
    ],
)
def test_annotations(chart_resources: List[Dict[str, Any]], expected_annotations: Dict[str, str]) -> None:
    """Make sure that annotations are working"""
    # based on apache/airflow:chart/tests/tests_annotations::test_annotations_are_added

    # there's only one resource because we sepecified show_only.
    assert len(chart_resources) == 1
    service_account = chart_resources[0]

    for name, value in expected_annotations.items():
        assert name in service_account["metadata"]["annotations"]
        assert value == service_account["metadata"]["annotations"][name]
