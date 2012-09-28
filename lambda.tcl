proc lambda {arguments body args} {
    return [list ::apply [list $arguments $body] {*}$args]
}

proc lambda@ {ns arguments body args} {
    return [list ::apply [list $arguments $body $ns] {*}$args]
}

package provide lambda 0

