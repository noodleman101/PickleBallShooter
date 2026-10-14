import math

#everything is in meters and degrees


launchingDimPos = [
    [-2.548, -1.274, 0, 1.274, 2.548],    # X positions (cols 0-4)
    [ 6.206,  5.313, 4.420, 3.527, 2.634] # Y positions (rows 0-4)
]
 
landingDimPos = [
    [-2.748, -1.832, -0.916, 0, 0.916, 1.832, 2.748], # X positions (cols 0-6)
    [-2.434, -3.427, -4.420, -5.413, -6.406]          # Y positions (rows 0-4)
]

# [(launch distance to net),
# (landing distances to net),
#(point 1 power, point 2 power, point 3 power),
#(point 1 angle, point 2 power, point 3 power)]

pointA = [(2.636,2.801,3.053),(2.436,4.700,7.424),(7.8,11.2,15.3),(32.5,22.25,17.75)]
pointB = [(4.422,4.600,4.921),(2.435,4.600,7.131),(12,17,22),(17,15,12)]
pointC = [(6.208,6.382,6.731),(2.435,4.545,6.948),(14,20,25),(15,13,11)]
powerOne = [pointA,pointB,pointC]

pointE = [(2.636,2.801,3.053),(2.436,4.700,7.424),(10,15,20),(20,16,15)]
pointF = [(4.422,4.600,4.921),(2.435,4.600,7.131),(12,17,22),(17,15,12)]
pointG = [(6.208,6.382,6.731),(2.435,4.545,6.948),(14,20,25),(15,13,11)]
powerTwo = [pointE,pointF,pointG]

pointH = [(2.636,2.801,3.053),(2.436,4.700,7.424),(10,15,20),(20,16,15)]
pointI = [(4.422,4.600,4.921),(2.435,4.600,7.131),(12,17,22),(17,15,12)]
pointJ = [(6.208,6.382,6.731),(2.435,4.545,6.948),(14,20,25),(15,13,11)]
powerThree = [pointH,pointI,pointJ]

pointK = [(2.636,2.801,3.053),(2.436,4.700,7.424),(10,15,20),(20,16,15)]
pointL = [(4.422,4.600,4.921),(2.435,4.600,7.131),(12,17,22),(17,15,12)]
pointM = [(6.208,6.382,6.731),(2.435,4.545,6.948),(14,20,25),(15,13,11)]
powerFour = [pointK,pointL,pointM]


powerSets = {"Slow": powerOne, "Medium": powerTwo, "Fast": powerThree}
def setInputs(launch, landing, power):
    global inputLaunch, inputLanding, allPoints
    inputLaunch = launch
    inputLanding = landing
    allPoints = powerSets[power]


inputLaunch = (4,4)
inputLanding = (5,0)
allPoints = powerOne     #powerOne, powerTwo, powerThree, powerFour



def getPositions():
    shooterX = launchingDimPos[0][inputLaunch[0]]
    shooterY = launchingDimPos[1][inputLaunch[1]]
    goalX    = landingDimPos[0][inputLanding[0]]
    goalY    = landingDimPos[1][inputLanding[1]]
 
    dx = goalX - shooterX
    dy = goalY - shooterY
    
    return (shooterY, dx, dy)

   
def getTurretAngle():

    shooterY, dx, dy = getPositions()
    
    angle = (-1 * ((math.degrees(math.atan2(dx, dy))) % 360 - 180))
    return round(angle, 2)


def getRelativePositions ():

    shooterY, dx, dy = getPositions()
    
    ratioToNet = abs(shooterY/dy)
    totalDistance = math.sqrt(dx*dx + dy*dy)
    distanceToNet = totalDistance*ratioToNet
    distanceFromNetToGoal = (totalDistance*(1-ratioToNet))
    
    return round(distanceToNet,3),round(distanceFromNetToGoal,3)

    
def linearInterpolation ():
    
    launchPoint, landingPoint = getRelativePositions()
    
    launchID = 0
    landID = 0
    tLaunch = 0.0
    tLanding = 0.0
    
    if launchPoint < allPoints[0][0][0] or launchPoint > allPoints[-1][0][-1]:
        return "Value out of range"
    
    for i in range(len(allPoints)-1):
        x0 = allPoints[i][0][i]
        x1 = allPoints[i+1][0][i+1]
        
        if x0 == launchPoint:
            tLaunch = 0
            launchID = i
            break
        elif launchPoint == x1:
            tLaunch = 1
            launchID = i
            break
        elif x0 <= launchPoint <= x1:
            tLaunch = (launchPoint - x0) / (x1- x0)
            launchID = i
            break
        
    if landingPoint < allPoints[0][1][0] or landingPoint > allPoints[-1][1][-1]:
        return "Value out of range"
        
    for n in range(len(allPoints)-1):
        y0 = allPoints[launchID][1][n]
        y1 = allPoints[launchID+1][1][n+1]
        
        if y0 == landingPoint:
            tLanding = 0.0
            landID = n
            break
        elif y1 == landingPoint:
            tLanding = 1.0
            landID = n
            break
        elif y0 <= landingPoint <= y1:
            tLanding = (landingPoint - y0) / (y1-y0)
            landID = n
            break
    
# --- THE 4 CASES (Bilinear Interpolation) ---
    # j00 = launch index i, land index n
    # j11 = launch index i+1, land index n+1
    
    def get_val(l_idx,index, d_idx):
        return allPoints[l_idx][index][d_idx] # 2 is Power

    j00 = get_val(launchID,2, landID)
    j10 = get_val(launchID + 1,2, landID)
    j01 = get_val(launchID,2, landID + 1)
    j11 = get_val(launchID + 1,2, landID + 1)

    # This single formula covers all 4 cases! 
    # If tLaunch is 0, it ignores the "1" indices.
    # If tLanding is 0, it ignores the "n+1" indices.
    finalSpeed = (j00 * (1 - tLaunch) * (1 - tLanding) +
                   j10 * tLaunch * (1 - tLanding) +
                   j01 * (1 - tLaunch) * tLanding +
                   j11 * tLaunch * tLanding)
    
    
    k00 = get_val(launchID,3, landID)
    k10 = get_val(launchID + 1,3, landID)
    k01 = get_val(launchID,3, landID + 1)
    k11 = get_val(launchID + 1,3, landID + 1)

    # This single formula covers all 4 cases! 
    # If tLaunch is 0, it ignores the "1" indices.
    # If tLanding is 0, it ignores the "n+1" indices.
    finalAngle = (k00 * (1 - tLaunch) * (1 - tLanding) +
                   k10 * tLaunch * (1 - tLanding) +
                   k01 * (1 - tLaunch) * tLanding +
                   k11 * tLaunch * tLanding)
    

    return round(finalSpeed,4), round(finalAngle,4)

if __name__ == "__main__":
    print(linearInterpolation())
    print(getRelativePositions())

