global DepthList=#()
global BoneChainList=#()
global BoneChainNameList=#()
global OldCurve=undefined
global Curve=undefined
global BoneChainPathLength
global BonePercentList=#()
global KnotsList=#()
global BoneChainListForward=#()
global PointIns=#()
global originTrans=#()
struct TreeNode
(
	_Bone,
	_Depth,
	_Children
)
Fn CreateTree parent_Node=
(
	depth=parent_Node._Depth
	parent_Node._Children=#()
	for child in parent_Node._Bone.children do 
	(
		child_Node=TreeNode()
		child_Node._Depth=depth+1
		child_Node._Bone=child
		append parent_Node._Children child_Node
		if child.children.count>=1 then 
		(
			CreateTree child_Node
		)
		else 
		(
			append Depthlist child_Node._Depth
			return 0
		)
		
	)
)
Fn SelectAllBones=
(
	clearSelection()
	for b in BoneChainList do 
	(
		selectMore b
	)
)
Fn GetBoneChain boneFrom=
(
	append BoneChainList boneFrom
	if boneFrom.parent!=undefined do 
	(
		GetBoneChain boneFrom.parent
	)
	
)
Fn GetBoneNameList =
(
	for i=1 to BoneChainList.count do 
	(
		BoneChainNameList[i]=BoneChainList[BoneChainList.count+1-i].name
		BoneChainListForward[i]=BoneChainList[BoneChainList.count+1-i]
	)
	
)
Fn GetLastBone parent_Node maxDepth &lastBone=
(
	
	if parent_Node._Depth<maxDepth then 
	(
		if parent_Node._Children!=undefined do
		(
			for child_Node in parent_Node._Children do
			(
				GetLastBone child_Node maxDepth &lastBone
			)
		)
		
	)
	if parent_Node._Depth==maxDepth then
	(	
		lastBone=parent_Node._Bone
	)
	
)

Fn GetBoneChainByRootBone obj=
(

	if classof obj!=BoneGeometry then 
	(
		messagebox "请选择骨骼"
		return 0
	)
	--init
	Depthlist=#()
	BoneChainList=#()
	BoneChainNameList=#()
	BonePercentList=#()
	BoneChainPathLength=0
	BoneChainListForward=#()
	originTrans=#()
	root_Node=TreeNode()
	root_Node._Depth=0
	root_Node._Bone=obj
	append Depthlist 0
	CreateTree root_Node
	local maxDepth=(amax Depthlist )
	--print ("max depth:"+maxDepth as string)
	
	local lastBone
	GetLastBone root_Node maxDepth &lastBone
	GetBoneChain lastBone
	SelectAllBones()
	GetBoneNameList()
	--print BoneChainList
	for b in  BoneChainList do
	(
		BoneChainPathLength+=b.length
	)
	for i=1 to BoneChainList.count do 
	(
		originTrans[i]=BoneChainList[i].rotation.controller.value
	)
	local temp=0
	for i=1 to BoneChainListForward.count do
	(
		BonePercentList[i]=(temp+BoneChainListForward[i].length)/BoneChainPathLength
		temp+=BoneChainListForward[i].length
	)
	--print BonePercentList
)

rollout CFBCToolRollout "CurveForBoneChain" width:240 height:400
(
	pickbutton  'btn2' "选择根骨骼" pos:[49,26] width:103 height:37 align:#left
	listBox 'lbx1' "BoneList" pos:[45,74] width:131 height:8 align:#left
	checkButton 'ckb1' "画线模式" pos:[52,239] width:115 height:42 align:#left
	button  're' "重置" pos:[52,299] width:115 height:42 align:#left

	groupBox 'grp2' "编辑" pos:[31,210] width:159 height:174 align:#left
	hyperLink hl "[项目地址]:请点我查看" pos:[51,360] color:[255,0,0] address:"https://github.com/ever17-luqc/3dsmax-CurveToBoneTool"	align:#center  width:200

	on 'btn2' picked obj do 
	(
		GetBoneChainByRootBone obj
		'lbx1'.items=BoneChainNameList
	)

	Fn setCurve n=
	(
		if Curve!=undefined do OldCurve=Curve
		
		if n!=undefined do Curve=n
		
		if OldCurve!=undefined do 
		(
			delete OldCurve
		)
	)
	on CFBCToolRollout close do
    (
        print "spine to max tool closed"
		
		if PointIns.count>0 do 
		(
			for p in PointIns do 
			(
				delete p
			)
		)
		
    )
	on  're' pressed do 
	(
		for i=1 to BoneChainList.count do 
		(
			BoneChainList[i].rotation.controller.value=originTrans[i]
		)
		print "reset"
	)
	on 'ckb1' changed state do 
	(
		if state==on then 
		(
			try
			(
				if Curve!=undefined do delete Curve
				if OldCurve!=undefined do delete OldCurve
				if PointIns.count>0 do 
				(
					for p in PointIns do 
					(
						delete p
					)
				)
				OldCurve=undefined
				Curve=undefined
				
				startObjectCreation FreehandSpline  newNodeCallback:setCurve
				if Curve!=undefined do 
				(
					addmodifier Curve (Edit_Spline ())		
					--按照百分比添加knot
					convertToSplineShape Curve
					segsCount=numSegments Curve 1
					--segLengths=getSegLengths Curve 1 cum:true
					--print segLengths	
					-- segPercents=#()
					-- append segPercents 0
					-- for i=1 to (segLengths.count-1)/2 do 
					-- (
						
					-- 	append (segPercents) (segLengths[i])
					-- 	temp=segLengths[i]
					-- )
					
					if BonePercentList.count==0 do 
					(
						BoneChainNameList "请选择骨骼"
						'ckb1'.state=off
						return 0
					) 
					-- for i=1 to BonePercentList.count do 
					-- (
					-- 	for j=1 to segLengths.count do 
					-- 	(
					-- 		if segLengths[j]>BonePercentList[BonePercentList.count+1-i] do 
					-- 		(
					-- 			ratio=0
					-- 			if j==1 then 
					-- 			(
					-- 				ratio=(segLengths[j]-BonePercentList[BonePercentList.count+1-i])/(segLengths[j])
					-- 			)
					-- 			else 
					-- 			(
					-- 				ratio=(segLengths[j]-BonePercentList[BonePercentList.count+1-i])/(segLengths[j]-segLengths[j-1])
					-- 			)
								
					-- 			refineSegment Curve 1 j ratio
								
					-- 			exit
					-- 		)
					-- 	)
					-- )
					-- updateShape Curve
					-- --获得对应关节位置的knot
					-- segLengths=#()
					-- segPercents=#()
					-- segLengths=getSegLengths Curve 1 cum:true
					
					-- for i=1 to (segLengths.count-1)/2 do 
					-- (
						
					-- 	append (segPercents) (segLengths[i])
					-- 	temp=segLengths[i]
					-- )
					
					KnotsList=#()
					append KnotsList (interpCurve3D Curve 1 0 )
					for percent in BonePercentList do 
					(
						append KnotsList (interpCurve3D Curve 1 percent )
					)
					
					PointIns=#()
					for knot in KnotsList do
					(
						temp=Point()
						temp.pos=knot
						append PointIns temp
					)
					local NormalizedDirList=#()
					for i=1 to KnotsList.count-1 do 
					(
						vTM = (getViewTM())
						local dir=normalize (KnotsList[i+1]*vTM-KnotsList[i]*vTM)
						append NormalizedDirList dir
					)
				
					undo on
					(
						for i=2 to BoneChainListForward.count do 
						(
							local vTM = (getViewTM())
							p1V=BoneChainListForward[i].pos*vTM
							p2V=BoneChainListForward[i-1].pos*vTM
							dirOri=normalize(p1V-p2V)
							dirTarget=NormalizedDirList[i-1]
							dirOri=[dirOri.x,dirOri.y,0]
							dirTarget=[dirTarget.x,dirTarget.y,0]
							dirOri=normalize(dirOri)
							dirTarget=normalize(dirTarget)
							sign=if(cross dirOri dirTarget).z>0 then 1 else -1
							theRotAxis = (Inverse(vTM)).row3*sign
							theAngle= acos (dot dirTarget dirOri  )
							theQuat = quat theAngle theRotAxis	
							rotate BoneChainListForward[i-1] theQuat

							-- dirOri=normalize(BoneChainListForward[i].pos-BoneChainListForward[i-1].pos)
							-- dirTarget=NormalizedDirList[i-1]
							-- theRotAxis = normalize (cross dirOri dirTarget   )
							
							
							-- theAngle= acos (dot dirTarget dirOri  )
							-- theQuat = quat theAngle theRotAxis	
							-- rotate BoneChainListForward[i-1] theQuat
							
						
						)
						local lastIndex=BoneChainListForward.count
						if BoneChainListForward[lastIndex].length!=0 do 
						(
							local vTM = (getViewTM())
							tempBone=BoneSys.createBone [0,0,0] [0,0,0] [0,-1,0]
							tempBone.pos=[BoneChainListForward[lastIndex].length,0,0]*(BoneChainListForward[lastIndex].transform)
							tempBone.parent=BoneChainListForward[lastIndex]

							p1V=tempBone.pos*vTM
							p2V=BoneChainListForward[lastIndex].pos*vTM
							dirOri=normalize(p1V-p2V)
							dirTarget=NormalizedDirList[lastIndex]
							dirOri=[dirOri.x,dirOri.y,0]
							dirTarget=[dirTarget.x,dirTarget.y,0]
							dirOri=normalize(dirOri)
							dirTarget=normalize(dirTarget)
							sign=if(cross dirOri dirTarget).z>0 then 1 else -1
							theRotAxis = (Inverse(vTM)).row3*sign
							theAngle= acos (dot dirTarget dirOri  )
							theQuat = quat theAngle theRotAxis	
							rotate BoneChainListForward[lastIndex] theQuat
							
							-- dirOri=normalize(tempBone.pos-BoneChainListForward[lastIndex].pos)
							-- dirTarget=NormalizedDirList[lastIndex]
							-- theRotAxis = normalize (cross dirOri dirTarget   )
							
							
							-- theAngle= acos (dot dirTarget dirOri  )
							-- theQuat = quat theAngle theRotAxis	
							-- rotate BoneChainListForward[lastIndex] theQuat
							 delete tempBone
						)
					)
					
				


				)
				
				'ckb1'.state=off
				
			
				
			)
			catch
			(
				messageBox "请勿手动删除Curve!!!请重启插件"
			)
			
			
		)
		else
		(
			actionMan.executeAction 0 "50001"  -- Tools: Select and Move
			
			

		)
		
		
	)
	

)
CreateDialog CFBCToolRollout