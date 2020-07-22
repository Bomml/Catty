/**
 *  Copyright (C) 2010-2020 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

#import "UserDataContainer.h"
#import "Pocket_Code-Swift.h"
#import "OrderedMapTable.h"
#include "SpriteObject.h"
#import <pthread.h>

@implementation UserDataContainer

static pthread_mutex_t variablesLock;

- (id)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&variablesLock,NULL);
    }
    return self;
}

- (void)dealloc
{
    NSDebug(@"Dealloc Variables and Lists");
    [self.objectVariableList removeAllObjects];
    [self.programVariableList removeAllObjects];
    [self.objectListOfLists removeAllObjects];
    [self.programListOfLists removeAllObjects];
    self.programVariableList = nil;
    self.objectVariableList = nil;
    self.programListOfLists = nil;
    self.objectListOfLists = nil;
    pthread_mutex_destroy(&variablesLock);
}

#pragma mark custom getters and setters

- (OrderedMapTable*)objectVariableList
{
    // lazy instantiation
    if (! _objectVariableList)
        _objectVariableList = [OrderedMapTable weakToStrongObjectsMapTable];
    return _objectVariableList;
}

- (OrderedMapTable*)objectListOfLists
{
    // lazy instantiation
    if (! _objectListOfLists)
        _objectListOfLists = [OrderedMapTable weakToStrongObjectsMapTable];
    return _objectListOfLists;
}

- (NSMutableArray*)programVariableList
{
    // lazy instantiation
    if (! _programVariableList)
        _programVariableList = [NSMutableArray array];
    return _programVariableList;
}

- (NSMutableArray*)programListOfLists
{
    // lazy instantiation
    if (! _programListOfLists)
        _programListOfLists = [NSMutableArray array];
    return _programListOfLists;
}


- (UserVariable*)getUserVariableNamed:(NSString*)name forSpriteObject:(SpriteObject*)sprite
{
    NSArray *objectUserVariables = [self.objectVariableList objectForKey:sprite];
    UserVariable *variable = [self findUserVariableNamed:name inArray:objectUserVariables];

    if (! variable) {
        variable = [self findUserVariableNamed:name inArray:self.programVariableList];
    }
    return variable;
}

- (UserList*)getUserListNamed:(NSString*)name forSpriteObject:(SpriteObject*)sprite
{
    NSArray *objectUserLists = [self.objectListOfLists objectForKey:sprite];
    UserList *list = [self findUserListNamed:name inArray:objectUserLists];
    
    if (! list) {
        list = [self findUserListNamed:name inArray:self.programListOfLists];
    }
    return list;
}

- (BOOL)removeUserVariableNamed:(NSString*)name forSpriteObject:(SpriteObject*)sprite
{
    NSMutableArray *objectUserVariables = [self.objectVariableList objectForKey:sprite];
    UserVariable *variable = [self findUserVariableNamed:name inArray:objectUserVariables];
    if (variable) {
        [self removeObjectUserVariableNamed:name inArray:objectUserVariables forSpriteObject:sprite];
        return YES;
    } else {
        variable = [self findUserVariableNamed:name inArray:self.programVariableList];
        if (variable) {
                [self removeProjectUserVariableNamed:name];
            return YES;
        }
    }
    return NO;
}

- (BOOL)removeUserListNamed:(NSString*)name forSpriteObject:(SpriteObject*)sprite
{
    NSMutableArray *objectUserLists = [self.objectListOfLists objectForKey:sprite];
    UserVariable *list = [self findUserVariableNamed:name inArray:objectUserLists];
    if (list) {
        [self removeObjectUserListNamed:name inArray:objectUserLists forSpriteObject:sprite];
        return YES;
    } else {
        list = [self findUserVariableNamed:name inArray:self.programListOfLists];
        if (list) {
            [self removeProjectUserListNamed:name];
            return YES;
        }
    }
    return NO;
}

- (UserVariable*)findUserVariableNamed:(NSString*)name inArray:(NSArray*)userVariables
{
    UserVariable *variable = nil;
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [userVariables count]; ++i) {
        UserVariable *var = [userVariables objectAtIndex:i];
        if ([var.name isEqualToString:name]) {
            variable = var;
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
    return variable;
}

- (UserList*)findUserListNamed:(NSString*)name inArray:(NSArray*)userLists
{
    UserList *list = nil;
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [userLists count]; ++i) {
        UserList *lis = [userLists objectAtIndex:i];
        if ([lis.name isEqualToString:name]) {
            list = lis;
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
    return list;
}

- (void)removeObjectUserVariableNamed:(NSString*)name inArray:(NSMutableArray*)userVariables forSpriteObject:(SpriteObject*)sprite
{
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [userVariables count]; ++i) {
        UserVariable *var = [userVariables objectAtIndex:i];
        if ([var.name isEqualToString:name]) {
            [userVariables removeObjectAtIndex:i];
            [self.objectVariableList setObject:userVariables forKey:sprite];
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
}

- (void)removeObjectUserListNamed:(NSString*)name inArray:(NSMutableArray*)userLists forSpriteObject:(SpriteObject*)sprite
{
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [userLists count]; ++i) {
        UserVariable *list = [userLists objectAtIndex:i];
        if ([list.name isEqualToString:name]) {
            [userLists removeObjectAtIndex:i];
            [self.objectListOfLists setObject:userLists forKey:sprite];
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
}

- (void)removeProjectUserVariableNamed:(NSString*)name
{
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [self.programVariableList count]; ++i) {
        UserVariable *var = [self.programVariableList objectAtIndex:i];
        if ([var.name isEqualToString:name]) {
            [self.programVariableList removeObjectAtIndex:i];
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
}

- (void)removeProjectUserListNamed:(NSString*)name
{
    pthread_mutex_lock(&variablesLock);
    for (int i = 0; i < [self.programListOfLists count]; ++i) {
        UserList *list = [self.programListOfLists objectAtIndex:i];
        if ([list.name isEqualToString:name]) {
            [self.programListOfLists removeObjectAtIndex:i];
            break;
        }
    }
    pthread_mutex_unlock(&variablesLock);
}

- (BOOL)isProjectVariable: (UserVariable*)userVariable
{
    for (UserVariable *userVariableToCompare in self.programVariableList) {
        if ([userVariableToCompare.name isEqualToString:userVariable.name]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isProjectList: (UserList*)userList
{
    for (UserVariable *userListToCompare in self.programListOfLists) {
        if ([userListToCompare.name isEqualToString:userList.name]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)addObjectVariable:(UserVariable*)userVariable forObject:(SpriteObject*)spriteObject
{
    NSMutableArray *array = [self.objectVariableList objectForKey:spriteObject];
    
    if (!array) {
        array = [NSMutableArray new];
    } else {
        for (UserVariable *userVariableToCompare in array) {
            if ([userVariableToCompare.name isEqualToString:userVariable.name]) {
                return NO;
            }
        }
    }
    
    [array addObject:userVariable];
    [self.objectVariableList setObject:array forKey:spriteObject];
    return YES;
}

- (BOOL)addObjectList:(UserList*)userList forObject:(SpriteObject*)spriteObject
{
    NSMutableArray *array = [self.objectListOfLists objectForKey:spriteObject];
    
    if (!array) {
        array = [NSMutableArray new];
    } else {
        for (UserVariable *userListToCompare in array) {
            if ([userListToCompare.name isEqualToString:userList.name]) {
                return NO;
            }
        }
    }
    
    [array addObject:userList];
    [self.objectListOfLists setObject:array forKey:spriteObject];
    return YES;
}

- (void)removeObjectVariablesForSpriteObject:(SpriteObject*)object
{
    [self.objectVariableList removeObjectForKey:object];
}

- (void)removeObjectListsForSpriteObject:(SpriteObject*)object
{
    [self.objectListOfLists removeObjectForKey:object];
}

- (BOOL)isEqualToUserDataContainer:(UserDataContainer*)userDataContainer
{
    //----------------------------------------------------------------------------------------------------
    // objectVariableList and objectListOfLists
    //----------------------------------------------------------------------------------------------------
    NSMutableArray *objVarsAndLists = [[NSMutableArray alloc] initWithCapacity: 2];
    [objVarsAndLists insertObject:[NSMutableArray arrayWithObjects:self.objectVariableList,userDataContainer.objectVariableList, nil] atIndex:0];
    [objVarsAndLists insertObject:[NSMutableArray arrayWithObjects:self.objectListOfLists,userDataContainer.objectListOfLists, nil] atIndex:1];
    
    for (NSMutableArray *varsOrLists in objVarsAndLists) {
        OrderedMapTable *thisVarsOrLists = [varsOrLists objectAtIndex:0];
        OrderedMapTable *otherVarsOrLists = [varsOrLists objectAtIndex:1];
        
        if ([thisVarsOrLists count] != [otherVarsOrLists count])
            return NO;
        
        NSUInteger index;
        for(index = 0; index < [thisVarsOrLists count]; ++index) {
            //----------------------------------------------------------------------------------------------------
            // 1) compare keys (sprite object of both object variables/lists)
            //----------------------------------------------------------------------------------------------------
            SpriteObject *firstObject = [thisVarsOrLists keyAtIndex:index];
            SpriteObject *secondObject = nil;
            NSUInteger idx;
            // look for object with same name (order in VariableList/ListOfLists can differ)
            for (idx = 0; idx < [otherVarsOrLists count]; ++idx) {
                SpriteObject *spriteObject = [otherVarsOrLists keyAtIndex:idx];
                if ([spriteObject.name isEqualToString:firstObject.name]) {
                    secondObject = spriteObject;
                    break;
                }
            }
            if (secondObject == nil || (! [firstObject isEqualToSpriteObject:secondObject]))
                return NO;
            
            //----------------------------------------------------------------------------------------------------
            // 2) compare values (all user variables/lists of both object variables)
            //----------------------------------------------------------------------------------------------------
            NSMutableArray *firstUserVariableList = [thisVarsOrLists objectAtIndex:index];
            NSMutableArray *secondUserVariableList = [otherVarsOrLists objectAtIndex:idx];
            
            if ([firstUserVariableList count] != [secondUserVariableList count])
                return NO;
            
            for (id<UserDataProtocol> firstVariable in firstUserVariableList) {
                id<UserDataProtocol> secondVariable = nil;
                // look for variable with same name (order in VariableList/ListOfLists can differ)
                for (id<UserDataProtocol> variable in secondUserVariableList) {
                    if ([firstVariable.name isEqualToString:variable.name]) {
                        secondVariable = variable;
                        break;
                    }
                }
                
                if ((secondVariable == nil) || (! [firstVariable isEqual:secondVariable]))
                    return NO;
            }
        }
    }

    //----------------------------------------------------------------------------------------------------
    // programVariableList and programListOfLists
    //----------------------------------------------------------------------------------------------------
    NSMutableArray *progVarsAndLists = [[NSMutableArray alloc] initWithCapacity: 2];
    [progVarsAndLists insertObject:[NSMutableArray arrayWithObjects:self.programVariableList,userDataContainer.programVariableList, nil] atIndex:0];
    [progVarsAndLists insertObject:[NSMutableArray arrayWithObjects:self.programListOfLists,userDataContainer.programListOfLists, nil] atIndex:1];
    
    for (NSMutableArray *varsOrLists in progVarsAndLists) {
        NSMutableArray *thisVarsOrLists = [varsOrLists objectAtIndex:0];
        NSMutableArray *otherVarsOrLists = [varsOrLists objectAtIndex:1];
        
        if ([thisVarsOrLists count] != [otherVarsOrLists count])
            return NO;
        
        for (id<UserDataProtocol> firstVariable in thisVarsOrLists) {
            id<UserDataProtocol> secondVariable = nil;
            // look for variable with same name (order in variable list can differ)
            for (id<UserDataProtocol> variable in otherVarsOrLists) {
                if ([firstVariable.name isEqualToString:variable.name]) {
                    secondVariable = variable;
                    break;
                }
            }
            if ((secondVariable == nil) || (! [firstVariable isEqual:secondVariable]))
                return NO;
        }
    }
    return YES;
}

- (id)mutableCopy
{
    UserDataContainer *copiedUserDataContainer = [UserDataContainer new];
    copiedUserDataContainer.objectVariableList = [self.objectVariableList mutableCopy];
    copiedUserDataContainer.programVariableList = [self.programVariableList mutableCopy];
    copiedUserDataContainer.objectListOfLists = [self.objectListOfLists mutableCopy];
    copiedUserDataContainer.programListOfLists = [self.programListOfLists mutableCopy];

    return copiedUserDataContainer;
}

@end
