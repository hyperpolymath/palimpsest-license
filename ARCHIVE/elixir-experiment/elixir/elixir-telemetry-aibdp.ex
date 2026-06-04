# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
# Telemetry example:
:telemetry.attach("aibdp_manifest", [:palimpsest, :manifest, :request], fn _event, %{format: format}, _metadata ->
  StatsD.increment("aibdp.manifest_served.#{format}")
end)
