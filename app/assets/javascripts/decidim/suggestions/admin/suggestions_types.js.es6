(() => {
  const $scope = $("#promoting-committee-details");

  const $promotingCommitteeCheckbox = $(
    "#suggestions_type_promoting_committee_enabled",
    $scope
  );

  const toggleVisibility = () => {
    if ($promotingCommitteeCheckbox.is(":checked")) {
      $(".suggestion-minimum-committee-members-details", $scope).show();
    } else {
      $(".suggestion-minimum-committee-members-details", $scope).hide();
    }
  };

  $($promotingCommitteeCheckbox).click(() => toggleVisibility());

  toggleVisibility();
})();
