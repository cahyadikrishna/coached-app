import { Controller } from "@hotwired/stimulus"
import * as htmlToImage from "html-to-image"
import polyline from "@mapbox/polyline"

export default class extends Controller {
  static targets = [
    "preview",
    "svg",
    "path",
    "metric",
    "aspectButton",
    "exportStatus"
  ]

  static values = {
    polyline: String,
    activity: Object,
    filename: String
  }

  static classes = [ "story", "square" ]

  connect() {
    this.currentAspect = "story"
    this.renderRoute()
    this.updatePaceOrSpeed()
    this.updateFilename()
  }

  // ---------------------------------------------------------------------------
  // Aspect ratio
  // ---------------------------------------------------------------------------

  setAspectRatio(event) {
    const ratio = event.params.aspectRatio
    if (ratio === this.currentAspect) return

    this.currentAspect = ratio

    this.aspectButtonTargets.forEach((button) => {
      const active = button.dataset.overlayGeneratorAspectRatioParam === ratio
      button.setAttribute("aria-pressed", active.toString())
      button.classList.toggle("bg-primary", active)
      button.classList.toggle("text-primary-foreground", active)
      button.classList.toggle("bg-muted", !active)
    })

    this.previewTarget.classList.remove(...this.storyClasses, ...this.squareClasses)
    this.previewTarget.classList.add(...(ratio === "story" ? this.storyClasses : this.squareClasses))
  }

  // ---------------------------------------------------------------------------
  // Metric visibility
  // ---------------------------------------------------------------------------

  toggleMetric(event) {
    const metric = event.params.metric
    const visible = event.target.checked

    this.metricTargets.forEach((element) => {
      if (element.dataset.metric === metric) {
        element.classList.toggle("hidden", !visible)
      }
    })
  }

  // ---------------------------------------------------------------------------
  // Route rendering
  // ---------------------------------------------------------------------------

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
      console.error("Failed to decode activity polyline:", error)
    }
  }

  buildSvgPath(points) {
    const padding = 24
    const lats = points.map((p) => p[0])
    const lngs = points.map((p) => p[1])

    const minLat = Math.min(...lats)
    const maxLat = Math.max(...lats)
    const minLng = Math.min(...lngs)
    const maxLng = Math.max(...lngs)

    const latRange = maxLat - minLat || 1
    const lngRange = maxLng - minLng || 1

    const viewBoxSize = 1000
    const available = viewBoxSize - padding * 2

    // Preserve aspect ratio by using the larger range as the scale basis and
    // centering the smaller dimension inside the square viewBox.
    const scale = Math.max(latRange, lngRange) / available

    const width = lngRange / scale
    const height = latRange / scale

    const offsetX = (viewBoxSize - width) / 2
    const offsetY = (viewBoxSize - height) / 2

    const commands = points.map((point, index) => {
      const x = offsetX + (point[1] - minLng) / scale
      const y = offsetY + (maxLat - point[0]) / scale // flip Y so north is up
      return `${index === 0 ? "M" : "L"} ${x.toFixed(2)} ${y.toFixed(2)}`
    })

    this.svgTarget.setAttribute("viewBox", `0 0 ${viewBoxSize} ${viewBoxSize}`)
    return commands.join(" ")
  }

  // ---------------------------------------------------------------------------
  // Pace / Speed label
  // ---------------------------------------------------------------------------

  updatePaceOrSpeed() {
    const activity = this.activityValue || {}
    const type = (activity.type || "").toLowerCase()
    const speed = parseFloat(activity.average_speed) || 0

    const container = this.metricTargets.find((element) => element.dataset.metric === "pace_or_speed")
    if (!container) return

    const valueElement = container.querySelector(".pace-or-speed-value")
    const labelElement = container.querySelector(".pace-or-speed-label")
    if (!valueElement || !labelElement) return

    if (speed <= 0) {
      valueElement.textContent = "—"
      labelElement.textContent = "Pace"
      return
    }

    const isRunOrWalk = [ "run", "walk", "hike" ].includes(type)

    if (isRunOrWalk) {
      const secondsPerKm = 1000 / speed
      const minutes = Math.floor(secondsPerKm / 60)
      const seconds = Math.round(secondsPerKm % 60)
      valueElement.textContent = `${minutes}:${seconds.toString().padStart(2, "0")} /km`
      labelElement.textContent = "Pace"
    } else {
      valueElement.textContent = `${(speed * 3.6).toFixed(1)} km/h`
      labelElement.textContent = "Avg Speed"
    }
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  async download() {
    const dataUrl = await this.renderPng()
    if (!dataUrl) return

    const link = document.createElement("a")
    link.href = dataUrl
    link.download = this.filenameValue
    document.body.appendChild(link)
    link.click()
    link.remove()
  }

  async copyToClipboard() {
    const dataUrl = await this.renderPng()
    if (!dataUrl) return

    try {
      const blob = await this.dataUrlToBlob(dataUrl)
      await navigator.clipboard.write([
        new ClipboardItem({ "image/png": blob })
      ])
      this.showStatus("Copied to clipboard", "success")
    } catch (error) {
      console.error("Clipboard copy failed:", error)
      this.showStatus("Copy failed. Try downloading instead.", "error")
    }
  }

  async renderPng() {
    this.showStatus("Generating graphic...", "neutral")

    try {
      // Force a sync layout flush so any pending Tailwind class changes are
      // painted before html-to-image reads the DOM.
      this.previewTarget.getBoundingClientRect()

      const dataUrl = await htmlToImage.toPng(this.previewTarget, {
        backgroundColor: null,
        pixelRatio: 2,
        cacheBust: true,
        skipFonts: true
      })

      this.clearStatus()
      return dataUrl
    } catch (error) {
      console.error("PNG rendering failed:", error)
      this.showStatus("Failed to generate graphic.", "error")
      return null
    }
  }

  dataUrlToBlob(dataUrl) {
    return fetch(dataUrl).then((response) => response.blob())
  }

  // ---------------------------------------------------------------------------
  // Filename
  // ---------------------------------------------------------------------------

  updateFilename() {
    const activity = this.activityValue || {}
    const id = activity.id || "activity"
    const date = new Date().toISOString().split("T")[0]
    this.filenameValue = `activity-${id}-overlay-${date}.png`
  }

  // ---------------------------------------------------------------------------
  // Status messages
  // ---------------------------------------------------------------------------

  showStatus(message, tone) {
    if (!this.hasExportStatusTarget) return

    this.exportStatusTarget.textContent = message
    this.exportStatusTarget.classList.remove("hidden", "text-green-600", "text-red-600", "text-muted-foreground")

    switch (tone) {
      case "success":
        this.exportStatusTarget.classList.add("text-green-600")
        break
      case "error":
        this.exportStatusTarget.classList.add("text-red-600")
        break
      default:
        this.exportStatusTarget.classList.add("text-muted-foreground")
    }

    if (tone !== "neutral") {
      setTimeout(() => this.clearStatus(), 3000)
    }
  }

  clearStatus() {
    if (!this.hasExportStatusTarget) return
    this.exportStatusTarget.textContent = ""
    this.exportStatusTarget.classList.add("hidden")
  }
}
