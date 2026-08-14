import { Controller } from "@hotwired/stimulus"
import polyline from "@mapbox/polyline"

export default class extends Controller {
  static targets = [ "svg", "path" ]

  static values = {
    polyline: String
  }

  connect() {
    this.renderRoute()
  }

  renderRoute() {
    this.pathTarget.setAttribute("d", "")

    if (!this.polylineValue || this.polylineValue.trim().length === 0) {
      return
    }

    try {
      const points = polyline.decode(this.polylineValue)
      if (points.length < 2) return

      const pathData = this.buildSvgPath(points)
      this.pathTarget.setAttribute("d", pathData)
    } catch (error) {
      console.error("Failed to decode route polyline:", error)
    }
  }

  buildSvgPath(points) {
    const padding = 20
    const lats = points.map((point) => point[0])
    const lngs = points.map((point) => point[1])

    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)
    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)

    const latRange = maxLat - minLat || 1
    const lngRange = maxLng - minLng || 1

    const viewBoxSize = 1000
    const available = viewBoxSize - padding * 2
    const scale = Math.max(latRange, lngRange) / available

    const width = lngRange / scale
    const height = latRange / scale
    const offsetX = (viewBoxSize - width) / 2
    const offsetY = (viewBoxSize - height) / 2

    const commands = points.map((point, index) => {
      const x = offsetX + (point[1] - minLng) / scale
      const y = offsetY + (maxLat - point[0]) / scale
      return `${index === 0 ? "M" : "L"} ${x.toFixed(2)} ${y.toFixed(2)}`
    })

    this.svgTarget.setAttribute("viewBox", `0 0 ${viewBoxSize} ${viewBoxSize}`)
    return commands.join(" ")
  }
}
