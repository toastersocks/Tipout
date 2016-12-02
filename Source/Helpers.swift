//
//  Helpers.swift
//  Tipout
//
//  Created by James Pamplona on 9/6/15.
//  Copyright © 2015 James Pamplona. All rights reserved.
//

import Foundation

/**
Returns a SubSequence of an ordered collection consisting of the leftover sequence of the longest collection (e.g. given two collections:
```swift

["1", "2", "3"]
```
and
```swift
["a", "b", "c", "d", "e"]
```

this function would return 

```swift
["d", "e"]
```

- parameter x: An ordered CollectionType which uses Int as its index
- parameter y: An ordered CollectionType which uses Int as its index

- returns: A SubSequence containing the objects in the longest collection who's indexes are not included in the shortest collection
*/

public func leftoverIndexes<T: Collection>(x: T, y: T) -> T.SubSequence where T.Index == Int {
    
    let longest  = max(x: x, y: y)
    let shortest = min(x: x, y: y)
    let leftover = longest[shortest.endIndex..<longest.endIndex]
    return leftover
}

/**
Given two collections, returns the longest.

- parameter x: A CollectionType
- parameter y: A CollectionType

- returns: The collection which has the highest `count` property. If both are the same, returns the collection passed as the second paramater.
*/
public func max<T: Collection>(x: T, y: T) -> T {
    return x.count > y.count ? x : y
}

/**
Given two collections, returns the shortest.

- parameter x: A CollectionType
- parameter y: A CollectionType

- returns: The collection which has the lowest `count` property. If both are the same, returns the collection passed as the second paramater.
*/
public func min<T: Collection>(x: T, y: T) -> T {
    return x.count < y.count ? x : y
}

/**
Truncates a Double value to the given number of decimal places

- parameter num:           The Double to be truncated
- parameter decimalPlaces: The number of decimal places to truncate to. (i.e. 1 to truncate down to the tenths place, 2 for hundreths etc...)

- returns: A double truncated to the given decimal place with no rounding taking place
*/
public func truncate(_ num: Double, toDecimalPlaces decimalPlaces: Int) -> Double {
    let factor = pow(Double(10), Double(decimalPlaces))
    return trunc(num * factor) / factor
}

/**
Given a Double, rounds it to the nearest unit given.

- parameter num:       A Double to round
- parameter toNearest: The numerical unit to round to (e.g. to round to the nearest 0.25, 2.68 would be rounded to 2.75)

- returns: The Double rounded to the nearest value given in `toNearest`
*/
public func round(_ num: Double, toNearest: Double) -> Double {
    if toNearest > 0 {
        return round(num / toNearest) * toNearest
    } else { return num }
}
