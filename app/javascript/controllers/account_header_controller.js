import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "actions", "link", "moreMenu", "moreButton"]
  connect() {
    this.navContainer = this.navTarget.parentElement
    this.calculateWidths()
    this.resize()
  }

  calculateWidths() {
    this.linkTargets.forEach((link) => link.dataset.width = link.clientWidth)
  }

  resize() {
    const targetWidth = this.navContainer.scrollWidth
    const realWidth = this.navContainer.clientWidth
    const menusWidth = this.menusWidth()
    const lastHiddenElementWidth = this.lastHiddenElementWidth()

    if (targetWidth > realWidth) { this.stashElement() }
    else if (realWidth - menusWidth >= lastHiddenElementWidth) { this.popElement() }
  }

  menusWidth() {
    const computedStyle = window.getComputedStyle(this.navContainer)
    let width = 0

    if (computedStyle.flexDirection === "row") {
      width = this.navTarget.clientWidth + this.actionsTarget.clientWidth
    } else {
      Array.from(this.navTarget.children).forEach(element => { width += element.clientWidth })
    }

    if (this.hasMoreButtonTarget && this.moreMenuTarget.children.length === 1) {
      width = width - this.moreButtonTarget.clientWidth
    }

    console.log(width)

    return width
  }

  stashElement() {
    if (!this.hasMoreMenuTarget) { this.createNav() }
    const links = this.navTarget.children
    const elementToHide = links[links.length - 2]
    this.moreMenuTarget.prepend(elementToHide)
    this.resize()
  }

  popElement() {
    if (!this.hasMoreMenuTarget) { return }
    const links = this.moreMenuTarget.children
    const elementToPop = links[0]
    this.navTarget.insertBefore(elementToPop, this.navTarget.lastElementChild)
    if (this.moreMenuTarget.children.length === 0) { this.destroyNav() }
  }

  lastHiddenElementWidth() {
    if (!this.hasMoreMenuTarget) { return false }
    const links = this.moreMenuTarget.children
    return links[0].dataset.width
  }

  createNav() {
    const moreMenu = document.createElement("ul")
    moreMenu.dataset.accountHeaderTarget = "moreMenu"
    moreMenu.classList.add("more-menu", "hidden")
    this.navContainer.parentElement.append(moreMenu)

    const moreButton = document.createElement("button")
    moreButton.dataset.accountHeaderTarget = "moreButton"
    moreButton.dataset.action = "account-header#toggleNav"
    moreButton.innerHTML = "Más..."
    this.navTarget.append(moreButton)
  }

  destroyNav() {
    this.moreMenuTarget.remove()
    this.moreButtonTarget.remove()
  }

  toggleNav() {
    if (!this.hasMoreMenuTarget) { return false }
    this.moreMenuTarget.classList.toggle("hidden")
  }
}
